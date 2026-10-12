import { Inject, Injectable } from '@nestjs/common';
import { RbacChecker } from '../../../platform/rbac/rbac';
import { type Account } from '../domain/account';
import { PROVIDER_GATE_SCREENS } from '../domain/session';
import { IDENTITY_REPOSITORY, type IdentityRepository } from '../port/identity-repository';
import { LEVEL_READER, type LevelReader, type Permissions } from '../port/outside-world';

/** What the signed-in account may do and see (GET /v1/me/permissions). */
export interface PermissionsView {
  readonly roles: readonly string[];
  readonly permissions: readonly string[];
  readonly screens: readonly string[];
  readonly providerGate: boolean;
}

/** The signed-in person's own account and grants. */
@Injectable()
export class MyAccount {
  constructor(
    @Inject(IDENTITY_REPOSITORY) private readonly repo: IdentityRepository,
    @Inject(RbacChecker) private readonly rbac: Permissions,
    @Inject(LEVEL_READER) private readonly levels: LevelReader,
  ) {}

  /** Returns the account. */
  get(accountId: string): Promise<Account> {
    return this.repo.accountById(accountId);
  }

  /**
   * Resolves the account's grants. A provider below Level 1 sees only the onboarding and
   * verification screens (PRD §8.5).
   */
  async permissions(accountId: string): Promise<PermissionsView> {
    const account = await this.repo.accountById(accountId);
    const grants = await this.rbac.grants(account.roles);
    const view = { roles: account.roles, ...grants, providerGate: false };
    if (!account.roles.includes('provider') || (await this.levels.getLevel(accountId)) >= 1) {
      return view;
    }
    const screens = grants.screens.filter(
      (id) => !id.startsWith('M') || PROVIDER_GATE_SCREENS.includes(id),
    );
    return { ...view, screens, providerGate: true };
  }
}
