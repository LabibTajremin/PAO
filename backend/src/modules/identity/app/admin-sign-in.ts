import { Inject, Injectable } from '@nestjs/common';
import { hashSecret, PASSWORD_PARAMS, verifySecret } from '../../../platform/auth/password-hash';
import { newTotpSecret } from '../../../platform/auth/totp';
import { CLOCK, type Clock } from '../../../platform/clock/clock';
import { DomainError, isDomainError } from '../../../platform/errors/domain-error';
import { ID_GENERATOR, type IdGenerator } from '../../../platform/ids/id-generator';
import {
  type Admin,
  adminLoginRefusal,
  CHALLENGE_TTL_MS,
  isStrongPassword,
  recordFailure,
  recordSuccess,
} from '../domain/admin';
import { IdentityReasons } from '../domain/reasons';
import { IDENTITY_REPOSITORY, type IdentityRepository } from '../port/identity-repository';
import { CHALLENGE_STORE, type ChallengeStore } from '../port/short-lived-state';

/** The first admin login step's result. */
export interface AdminChallenge {
  readonly id: string;
  /** Set on the first login, for the authenticator app; empty afterwards. */
  readonly enrolSecret: string;
  readonly enrolUrl: string;
  readonly mustChangePassword: boolean;
}

/** The admin password step and password change (A-01). */
@Injectable()
export class AdminSignIn {
  constructor(
    @Inject(IDENTITY_REPOSITORY) private readonly repo: IdentityRepository,
    @Inject(CHALLENGE_STORE) private readonly challenges: ChallengeStore,
    @Inject(CLOCK) private readonly clock: Clock,
    @Inject(ID_GENERATOR) private readonly ids: IdGenerator,
  ) {}

  /** Checks email and password and starts the TOTP step; wrong passwords lock out. */
  async login(email: string, password: string): Promise<AdminChallenge> {
    const admin = await this.adminByEmail(email);
    const now = this.clock.now();
    const refusal = adminLoginRefusal(admin, now);
    if (refusal) {
      throw new DomainError(refusal);
    }
    if (!(await verifySecret(password, admin.passwordHash))) {
      await this.save(recordFailure(admin, now));
      throw new DomainError(IdentityReasons.InvalidCredentials);
    }
    const cleared = recordSuccess(admin);
    await this.save(cleared);
    return this.startChallenge(cleared);
  }

  /** Replaces the password after checking the current one. */
  async changePassword(accountId: string, current: string, next: string): Promise<void> {
    const admin = await this.repo.adminById(accountId);
    if (!(await verifySecret(current, admin.passwordHash))) {
      throw new DomainError(IdentityReasons.InvalidCredentials);
    }
    if (!isStrongPassword(next)) {
      throw new DomainError(IdentityReasons.PasswordTooWeak);
    }
    const passwordHash = await hashSecret(next, PASSWORD_PARAMS);
    await this.save({ ...admin, passwordHash, mustChangePassword: false });
  }

  private async adminByEmail(email: string): Promise<Admin> {
    try {
      return await this.repo.adminByEmail(email);
    } catch (err) {
      if (isDomainError(err, IdentityReasons.AccountNotFound)) {
        throw new DomainError(IdentityReasons.InvalidCredentials);
      }
      throw err;
    }
  }

  private async startChallenge(admin: Admin): Promise<AdminChallenge> {
    const enrolment = admin.totpEnrolled ? { secret: '', url: '' } : newTotpSecret(admin.email);
    const id = this.ids.newId();
    await this.challenges.save(
      { id, adminId: admin.id, attempts: 0, enrolSecret: enrolment.secret },
      CHALLENGE_TTL_MS,
    );
    return {
      id,
      enrolSecret: enrolment.secret,
      enrolUrl: enrolment.url,
      mustChangePassword: admin.mustChangePassword,
    };
  }

  private save(admin: Admin): Promise<void> {
    return this.repo.inTx((tx) => tx.saveAdmin(admin));
  }
}
