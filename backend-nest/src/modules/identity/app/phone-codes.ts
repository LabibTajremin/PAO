import { Inject, Injectable } from '@nestjs/common';
import { CODE_PARAMS, hashSecret, verifySecret } from '../../../platform/auth/password-hash';
import { randomDigits } from '../../../platform/auth/random';
import { DomainError } from '../../../platform/errors/domain-error';
import { checkAttempt, CODE_LENGTH } from '../domain/code';
import { maskPhone, normalizePhone } from '../domain/phone';
import { IdentityReasons } from '../domain/reasons';
import { IDENTITY_REPOSITORY, type IdentityRepository } from '../port/identity-repository';
import { SMS_SENDER, type SmsSender } from '../port/outside-world';
import {
  CODE_STORE,
  type CodeStore,
  SEND_THROTTLE,
  type SendThrottle,
} from '../port/short-lived-state';

/** A one-time code was asked for too soon; carries how long the caller must wait. */
export class CodeRateLimitedError extends DomainError {
  constructor(readonly retryAfterMs: number) {
    super(IdentityReasons.RateLimited);
  }
}

/** Asks for a one-time code by SMS. */
export interface SendCodeInput {
  readonly phone: string;
  readonly purpose: string;
  /**
   * Undefined when the server sends a code on behalf of a signed-in user (an emergency
   * contact's code): those share no address, so a per-IP window would throttle every
   * provider at once.
   */
  readonly clientIp?: string;
}

/** Returns the E.164 phone, or throws InvalidPhone. */
export function phoneOrFail(raw: string): string {
  const phone = normalizePhone(raw);
  if (phone === undefined) {
    throw new DomainError(IdentityReasons.InvalidPhone);
  }
  return phone;
}

/**
 * Sends and checks one-time codes. A code sent for one purpose never satisfies another
 * (`login`, `delete_account`, `emergency_contact`).
 */
@Injectable()
export class PhoneCodes {
  constructor(
    @Inject(IDENTITY_REPOSITORY) private readonly repo: IdentityRepository,
    @Inject(CODE_STORE) private readonly codes: CodeStore,
    @Inject(SEND_THROTTLE) private readonly throttle: SendThrottle,
    @Inject(SMS_SENDER) private readonly sms: SmsSender,
  ) {}

  /** Rate-limits, stores the hash of a fresh 6-digit code and texts it; returns the phone. */
  async send(input: SendCodeInput): Promise<string> {
    const phone = phoneOrFail(input.phone);
    // Banned identities get no login code, so no SMS is paid for (PRD §6.4).
    if (input.purpose === 'login' && (await this.repo.isPhoneBlocked(phone))) {
      throw new DomainError(IdentityReasons.AccountBanned);
    }
    const wait = await this.throttle.retryAfterMs(phone, input.clientIp);
    if (wait > 0) {
      throw new CodeRateLimitedError(wait);
    }
    const code = randomDigits(CODE_LENGTH);
    await this.codes.save(input.purpose, phone, {
      hash: await hashSecret(code, CODE_PARAMS),
      attempts: 0,
    });
    const message = `PAO code: ${code}. Valid for 5 minutes. Never share it. / আপনার PAO কোড ${code}`;
    try {
      await this.sms.send(phone, message);
    } catch (cause) {
      throw new Error(`send code to ${maskPhone(phone)}`, { cause });
    }
    return phone;
  }

  /** Verifies a code, consuming it on success or lockout. */
  async check(purpose: string, phone: string, code: string): Promise<void> {
    const stored = await this.codes.get(purpose, phone);
    const attempt = checkAttempt(stored, await verifySecret(code, stored.hash));
    await (attempt.discard
      ? this.codes.delete(purpose, phone)
      : this.codes.incrementAttempts(purpose, phone));
    if (attempt.refusal) {
      throw new DomainError(attempt.refusal);
    }
  }

  /** Checks a code for a phone someone typed, e.g. an emergency contact's (PRD §6.2). */
  async checkTyped(rawPhone: string, purpose: string, code: string): Promise<void> {
    await this.check(purpose, phoneOrFail(rawPhone), code);
  }
}
