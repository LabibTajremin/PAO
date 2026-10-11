import { Inject, Injectable } from '@nestjs/common';
import { validateTotp } from '../../../platform/auth/totp';
import { CLOCK, type Clock } from '../../../platform/clock/clock';
import { DomainError } from '../../../platform/errors/domain-error';
import { CHALLENGE_ATTEMPTS, CHALLENGE_TTL_MS, type Challenge } from '../domain/admin';
import { IdentityReasons } from '../domain/reasons';
import { IDENTITY_REPOSITORY, type IdentityRepository } from '../port/identity-repository';
import { CHALLENGE_STORE, type ChallengeStore } from '../port/short-lived-state';
import { type Session, Sessions } from './sessions';

/** The admin authenticator step that completes a login (A-01). */
@Injectable()
export class AdminTotp {
  constructor(
    @Inject(IDENTITY_REPOSITORY) private readonly repo: IdentityRepository,
    @Inject(CHALLENGE_STORE) private readonly challenges: ChallengeStore,
    @Inject(Sessions) private readonly sessions: Sessions,
    @Inject(CLOCK) private readonly clock: Clock,
  ) {}

  /**
   * Completes a login with an authenticator code. On the first login the code confirms
   * enrolment and the new secret is saved.
   */
  async verify(challengeId: string, code: string): Promise<Session> {
    const challenge = await this.challenges.get(challengeId);
    const admin = await this.repo.adminById(challenge.adminId);
    const secret = challenge.enrolSecret === '' ? admin.totpSecret : challenge.enrolSecret;
    if (!(await validateTotp(code, secret, this.clock.now()))) {
      return this.fail(challenge);
    }
    await this.challenges.delete(challenge.id);
    const enrolled = { totpSecret: secret, totpEnrolled: true, lastLoginAt: this.clock.now() };
    await this.repo.inTx((tx) => tx.saveAdmin({ ...admin, ...enrolled }));
    return this.sessions.open(admin, 'admin');
  }

  private async fail(challenge: Challenge): Promise<never> {
    const attempts = challenge.attempts + 1;
    if (attempts >= CHALLENGE_ATTEMPTS) {
      await this.challenges.delete(challenge.id);
      throw new DomainError(IdentityReasons.ChallengeExpired);
    }
    await this.challenges.save({ ...challenge, attempts }, CHALLENGE_TTL_MS);
    throw new DomainError(IdentityReasons.TotpInvalid);
  }
}
