import { Inject, Injectable } from '@nestjs/common';
import { hashSecret, PASSWORD_PARAMS } from '../../../platform/auth/password-hash';
import { randomToken } from '../../../platform/auth/random';
import { CLOCK, type Clock } from '../../../platform/clock/clock';
import { DomainError, isDomainError } from '../../../platform/errors/domain-error';
import { ID_GENERATOR, type IdGenerator } from '../../../platform/ids/id-generator';
import { isAdminRoleSet } from '../domain/account';
import { type Admin } from '../domain/admin';
import { IdentityReasons } from '../domain/reasons';
import { IDENTITY_REPOSITORY, type IdentityRepository } from '../port/identity-repository';
import { Sessions } from './sessions';

/** Invites an admin. */
export interface CreateAdminInput {
  readonly email: string;
  readonly name: string;
  readonly roles: readonly string[];
}

/** Changes an admin's roles and/or active flag; absent fields stay as they are. */
export interface UpdateAdminInput {
  readonly adminId: string;
  readonly roles?: readonly string[];
  readonly active?: boolean;
}

/** Operations staff accounts (A-01, A-10). */
@Injectable()
export class AdminUsers {
  constructor(
    @Inject(IDENTITY_REPOSITORY) private readonly repo: IdentityRepository,
    @Inject(Sessions) private readonly sessions: Sessions,
    @Inject(CLOCK) private readonly clock: Clock,
    @Inject(ID_GENERATOR) private readonly ids: IdGenerator,
  ) {}

  /**
   * Creates an admin with a one-time temporary password; the first login forces a
   * password change and TOTP enrolment.
   */
  async create(input: CreateAdminInput): Promise<{ admin: Admin; temporaryPassword: string }> {
    if (!isAdminRoleSet(input.roles)) {
      throw new DomainError(IdentityReasons.RoleInvalid);
    }
    const email = input.email.trim().toLowerCase();
    if (await this.exists(email)) {
      throw new DomainError(IdentityReasons.EmailTaken);
    }
    const temporaryPassword = randomToken(12);
    const admin: Admin = {
      id: this.ids.newId(),
      phone: '',
      email,
      name: input.name,
      status: 'active',
      roles: [...input.roles],
      createdAt: this.clock.now(),
      deletedAt: null,
      passwordHash: await hashSecret(temporaryPassword, PASSWORD_PARAMS),
      mustChangePassword: true,
      totpSecret: '',
      totpEnrolled: false,
      failedAttempts: 0,
      lockedUntil: null,
      active: true,
      lastLoginAt: null,
    };
    await this.repo.inTx(async (tx) => {
      await tx.createAccount(admin);
      await tx.setRoles(admin.id, admin.roles);
      await tx.createAdminCredentials(admin.id, admin.passwordHash);
    });
    return { admin, temporaryPassword };
  }

  /** Changes an admin and ends their sessions, so new rights apply at once. */
  async update(input: UpdateAdminInput): Promise<Admin> {
    if (input.roles !== undefined && !isAdminRoleSet(input.roles)) {
      throw new DomainError(IdentityReasons.RoleInvalid);
    }
    const current = await this.repo.adminById(input.adminId);
    const admin = {
      ...current,
      roles: input.roles ?? current.roles,
      active: input.active ?? current.active,
    };
    await this.repo.inTx(async (tx) => {
      if (input.roles !== undefined) {
        await tx.setRoles(admin.id, admin.roles);
      }
      await tx.saveAdmin(admin);
    });
    await this.sessions.revokeAll(admin.id);
    return admin;
  }

  /** Every admin, by email. */
  list(): Promise<Admin[]> {
    return this.repo.listAdmins();
  }

  /**
   * Creates a demo admin with a known password unless the email exists; the seed uses
   * it for dev and staging. TOTP enrolment still happens at the first login.
   */
  async ensure(input: CreateAdminInput, password: string): Promise<void> {
    if (await this.exists(input.email.trim().toLowerCase())) {
      return;
    }
    const { admin } = await this.create(input);
    const passwordHash = await hashSecret(password, PASSWORD_PARAMS);
    await this.repo.inTx((tx) =>
      tx.saveAdmin({ ...admin, passwordHash, mustChangePassword: false }),
    );
  }

  private async exists(email: string): Promise<boolean> {
    try {
      await this.repo.adminByEmail(email);
      return true;
    } catch (err) {
      if (isDomainError(err, IdentityReasons.AccountNotFound)) {
        return false;
      }
      throw err;
    }
  }
}
