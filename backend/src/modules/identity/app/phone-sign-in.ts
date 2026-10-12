import { Inject, Injectable } from '@nestjs/common';
import { CLOCK, type Clock } from '../../../platform/clock/clock';
import { DomainError, isDomainError } from '../../../platform/errors/domain-error';
import { ID_GENERATOR, type IdGenerator } from '../../../platform/ids/id-generator';
import { IdentityEvents, type Role } from '../contract';
import { type Account, roleForApp, signInRefusal } from '../domain/account';
import { IdentityReasons } from '../domain/reasons';
import { IDENTITY_REPOSITORY, type IdentityRepository } from '../port/identity-repository';
import { PhoneCodes, phoneOrFail } from './phone-codes';
import { type Session, Sessions } from './sessions';

/** Completes a phone sign-in. */
export interface VerifyLoginInput {
  readonly phone: string;
  readonly code: string;
  /** `customer` or `partner`; the partner app grants the provider role. */
  readonly app: string;
}

/** Finds people by phone and registers newcomers, publishing what changed. */
@Injectable()
export class PhoneAccounts {
  constructor(
    @Inject(IDENTITY_REPOSITORY) private readonly repo: IdentityRepository,
    @Inject(CLOCK) private readonly clock: Clock,
    @Inject(ID_GENERATOR) private readonly ids: IdGenerator,
  ) {}

  /** The account with this phone, or undefined. */
  async find(phone: string): Promise<Account | undefined> {
    try {
      return await this.repo.accountByPhone(phone);
    } catch (err) {
      if (isDomainError(err, IdentityReasons.AccountNotFound)) {
        return undefined;
      }
      throw err;
    }
  }

  /** Creates an active account holding `role`. */
  async register(phone: string, role: string): Promise<Account> {
    const account: Account = {
      id: this.ids.newId(),
      phone,
      email: '',
      name: '',
      status: 'active',
      roles: [role],
      createdAt: this.clock.now(),
      deletedAt: null,
    };
    await this.repo.inTx(async (tx) => {
      await tx.createAccount(account);
      await tx.grantRole(account.id, role);
      const event = { accountId: account.id, phone, role: role as Role };
      await tx.publish(account.id, { name: IdentityEvents.AccountCreated, ...event });
    });
    return account;
  }

  /** Adds `role` unless the account holds it or may not sign in anyway. */
  async addRole(account: Account, role: string): Promise<Account> {
    if (account.roles.includes(role) || signInRefusal(account)) {
      return account;
    }
    await this.repo.inTx(async (tx) => {
      await tx.grantRole(account.id, role);
      const event = { accountId: account.id, role: role as Role };
      await tx.publish(account.id, { name: IdentityEvents.RoleGranted, ...event });
    });
    return { ...account, roles: [...account.roles, role] };
  }
}

/** Phone + one-time code sign-in for customers and providers (C-01, P-01). */
@Injectable()
export class PhoneSignIn {
  constructor(
    @Inject(PhoneAccounts) private readonly accounts: PhoneAccounts,
    @Inject(PhoneCodes) private readonly codes: PhoneCodes,
    @Inject(Sessions) private readonly sessions: Sessions,
  ) {}

  /**
   * Checks the code, creates the account on first sign-in or adds the app's role, and
   * opens a session.
   */
  async verify(input: VerifyLoginInput): Promise<Session> {
    const phone = phoneOrFail(input.phone);
    await this.codes.check('login', phone, input.code);
    const role = roleForApp(input.app);
    const existing = await this.accounts.find(phone);
    const account = existing
      ? await this.accounts.addRole(existing, role)
      : await this.accounts.register(phone, role);
    const refusal = signInRefusal(account);
    if (refusal) {
      throw new DomainError(refusal);
    }
    return this.sessions.open(account, input.app, !existing);
  }
}
