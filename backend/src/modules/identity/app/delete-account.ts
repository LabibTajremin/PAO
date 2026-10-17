import { Inject, Injectable } from '@nestjs/common';
import { DomainError } from '../../../platform/errors/domain-error';
import { IdentityEvents } from '../contract';
import { IdentityReasons } from '../domain/reasons';
import { IDENTITY_REPOSITORY, type IdentityRepository } from '../port/identity-repository';
import { PhoneCodes } from './phone-codes';
import { type Caller, Sessions } from './sessions';

/** Lets a person erase their own account (PRD §11). */
@Injectable()
export class AccountDeletion {
  constructor(
    @Inject(IDENTITY_REPOSITORY) private readonly repo: IdentityRepository,
    @Inject(PhoneCodes) private readonly codes: PhoneCodes,
    @Inject(Sessions) private readonly sessions: Sessions,
  ) {}

  /**
   * Erases the caller's identity after re-confirming with a one-time code: sessions
   * end, personal data is anonymised and AccountDeleted tells the other modules to
   * erase theirs.
   */
  async delete(caller: Caller, code: string): Promise<void> {
    const account = await this.repo.accountById(caller.accountId);
    if (account.phone === '') {
      throw new DomainError(IdentityReasons.AccountDeleted);
    }
    await this.codes.check('delete_account', account.phone, code);
    try {
      await this.repo.inTx(async (tx) => {
        await tx.setRoles(account.id, []);
        await tx.anonymiseAccount(account.id);
        await tx.publish(account.id, {
          name: IdentityEvents.AccountDeleted,
          accountId: account.id,
        });
      });
    } finally {
      // Sessions end even when erasing failed: the person asked to be signed out.
      await this.sessions.revokeAll(account.id);
    }
  }
}
