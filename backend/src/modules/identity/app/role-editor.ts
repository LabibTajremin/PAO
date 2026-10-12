import { Inject, Injectable } from '@nestjs/common';
import { DomainError } from '../../../platform/errors/domain-error';
import { type Grants, RbacChecker } from '../../../platform/rbac/rbac';
import { IdentityReasons } from '../domain/reasons';
import { IDENTITY_REPOSITORY, type IdentityRepository } from '../port/identity-repository';
import { type Permissions } from '../port/outside-world';

/** A role with its grants. */
export interface RoleDefinition extends Grants {
  readonly role: string;
}

/** Every role plus every known permission and screen, for the role editor (A-10). */
export interface RoleCatalogue {
  readonly roles: RoleDefinition[];
  readonly allPermissions: string[];
  readonly allScreens: string[];
}

/** The role editor (A-10). */
@Injectable()
export class RoleEditor {
  constructor(
    @Inject(IDENTITY_REPOSITORY) private readonly repo: IdentityRepository,
    @Inject(RbacChecker) private readonly rbac: Permissions,
  ) {}

  /** Returns every role with its grants and the catalogue to choose from. */
  async list(): Promise<RoleCatalogue> {
    const roles: RoleDefinition[] = [];
    for (const role of await this.repo.listRoles()) {
      roles.push({ role, ...(await this.repo.loadGrants(role)) });
    }
    const { permissions, screens } = await this.repo.catalogue();
    return { roles, allPermissions: permissions, allScreens: screens };
  }

  /**
   * Replaces a role's permissions and screens and bumps the RBAC version so every cached
   * grant refreshes (docs/build/02-architecture.md §6).
   */
  async update(def: RoleDefinition): Promise<RoleDefinition> {
    const roles = await this.repo.listRoles();
    const known = await this.repo.catalogue();
    const valid =
      roles.includes(def.role) &&
      def.permissions.every((p) => known.permissions.includes(p)) &&
      def.screens.every((s) => known.screens.includes(s));
    if (!valid) {
      throw new DomainError(IdentityReasons.RoleInvalid);
    }
    await this.repo.inTx((tx) => tx.replaceRole(def.role, def));
    await this.rbac.bumpVersion();
    return def;
  }
}
