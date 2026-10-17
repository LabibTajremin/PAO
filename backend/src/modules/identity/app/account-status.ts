import { Inject, Injectable } from '@nestjs/common';
import { DomainError } from '../../../platform/errors/domain-error';
import { IdentityEvents, type Role, type SetAccountStatusInput } from '../contract';
import { type Account, canChangeStatus } from '../domain/account';
import { IdentityReasons } from '../domain/reasons';
import {
  IDENTITY_REPOSITORY,
  type IdentityRepository,
  type IdentityWriter,
} from '../port/identity-repository';
import { Sessions } from './sessions';

/** Suspends, bans and reinstates accounts (A-05). */
@Injectable()
export class AccountStatusChanger {
  constructor(
    @Inject(IDENTITY_REPOSITORY) private readonly repo: IdentityRepository,
    @Inject(Sessions) private readonly sessions: Sessions,
  ) {}

  /**
   * Changes the status. Banning blocks the phone so it cannot sign up again (PRD §6.4);
   * suspending or banning ends every session.
   */
  async set(input: SetAccountStatusInput): Promise<Account> {
    const account = await this.repo.accountById(input.accountId);
    const to = input.status;
    if (!canChangeStatus(account, to)) {
      throw new DomainError(IdentityReasons.StatusChange);
    }
    await this.repo.inTx(async (tx) => {
      await tx.updateStatus(account.id, to);
      await updatePhoneBlock(tx, account, input);
      await tx.publish(account.id, {
        name: IdentityEvents.AccountStatusChanged,
        accountId: account.id,
        from: account.status,
        to,
        reason: input.reason,
        actorId: input.actorId,
        roles: account.roles as Role[],
      });
    });
    if (to !== 'active') {
      await this.sessions.revokeAll(account.id);
    }
    return { ...account, status: to };
  }
}

async function updatePhoneBlock(
  tx: IdentityWriter,
  account: Account,
  input: SetAccountStatusInput,
): Promise<void> {
  if (account.phone === '') {
    return;
  }
  if (input.status === 'banned') {
    await tx.blockPhone(account.phone, input.reason);
  } else if (account.status === 'banned') {
    await tx.unblockPhone(account.phone);
  }
}
