import { Inject, Injectable } from '@nestjs/common';
import { type AdminSeeder, type SeedAdmin } from '../../../../platform/seeding/seeders';
import {
  type Account,
  type CodePurpose,
  type IdentityService,
  type Role,
  type SetAccountStatusInput,
} from '../../contract';
import { type Account as DomainAccount } from '../../domain/account';
import { AccountStatusChanger } from '../../app/account-status';
import { AdminUsers } from '../../app/admin-users';
import { MyAccount } from '../../app/my-account';
import { PhoneCodes } from '../../app/phone-codes';

function toContract(a: DomainAccount): Account {
  return {
    id: a.id,
    phone: a.phone,
    email: a.email,
    roles: [...a.roles].sort() as Role[],
    status: a.status,
    createdAt: a.createdAt,
  };
}

/**
 * The identity contract for other modules in the process (PRD §9.3 rule 7). Its errors
 * already carry the contract's reasons.
 */
@Injectable()
export class InProcessIdentityService implements IdentityService {
  constructor(
    @Inject(MyAccount) private readonly accounts: MyAccount,
    @Inject(AccountStatusChanger) private readonly status: AccountStatusChanger,
    @Inject(PhoneCodes) private readonly codes: PhoneCodes,
  ) {}

  async getAccount(accountId: string): Promise<Account> {
    return toContract(await this.accounts.get(accountId));
  }

  async hasRole(accountId: string, role: Role): Promise<boolean> {
    return (await this.accounts.get(accountId)).roles.includes(role);
  }

  async setAccountStatus(input: SetAccountStatusInput): Promise<Account> {
    return toContract(await this.status.set(input));
  }

  async sendPhoneCode(phone: string, purpose: CodePurpose): Promise<void> {
    // No client IP: the provider's request already passed the per-user limits, and the
    // per-phone windows still apply to the contact's number.
    await this.codes.send({ phone, purpose });
  }

  checkPhoneCode(phone: string, purpose: CodePurpose, code: string): Promise<void> {
    return this.codes.checkTyped(phone, purpose, code);
  }
}

/** Creates the seed file's demo admins for `migrate seed`. */
@Injectable()
export class IdentityAdminSeeder implements AdminSeeder {
  constructor(@Inject(AdminUsers) private readonly admins: AdminUsers) {}

  ensureAdmin(admin: SeedAdmin, password: string): Promise<void> {
    return this.admins.ensure(admin, password);
  }
}
