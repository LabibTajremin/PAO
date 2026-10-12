import { type Account } from './account';
import { type IdentityReason, IdentityReasons } from './reasons';

/** Wrong passwords before an admin is locked out (A-01). */
export const ADMIN_MAX_FAILURES = 5;
/** How long a lockout lasts. */
export const ADMIN_LOCKOUT_MS = 15 * 60_000;
/** How long the second login step waits for the authenticator code. */
export const CHALLENGE_TTL_MS = 5 * 60_000;
/** Wrong authenticator codes before the challenge is dropped. */
export const CHALLENGE_ATTEMPTS = 5;
/** The shortest admin password. */
export const MIN_PASSWORD_LENGTH = 12;

/** An operations staff member's account plus credentials. */
export interface Admin extends Account {
  readonly passwordHash: string;
  readonly mustChangePassword: boolean;
  /** The authenticator secret once enrolled, else empty; encrypted at rest. */
  readonly totpSecret: string;
  readonly totpEnrolled: boolean;
  readonly failedAttempts: number;
  readonly lockedUntil: Date | null;
  readonly active: boolean;
  readonly lastLoginAt: Date | null;
}

/** The pending second login step (`mfa:{id}` in Redis). */
export interface Challenge {
  readonly id: string;
  readonly adminId: string;
  readonly attempts: number;
  /**
   * Set on the first login: the code must match this new secret, which is then saved.
   * Empty once the admin has enrolled.
   */
  readonly enrolSecret: string;
}

/** Why the admin may not log in now, or undefined when they may. */
export function adminLoginRefusal(a: Admin, now: Date): IdentityReason | undefined {
  if (!a.active || a.deletedAt !== null) {
    return IdentityReasons.AdminInactive;
  }
  return a.lockedUntil !== null && now < a.lockedUntil ? IdentityReasons.AdminLocked : undefined;
}

/** Counts a wrong password; reaching the limit locks the admin out and restarts the count. */
export function recordFailure(a: Admin, now: Date): Admin {
  const failedAttempts = a.failedAttempts + 1;
  if (failedAttempts < ADMIN_MAX_FAILURES) {
    return { ...a, failedAttempts };
  }
  return { ...a, failedAttempts: 0, lockedUntil: new Date(now.getTime() + ADMIN_LOCKOUT_MS) };
}

/** Clears failures after a correct password. */
export function recordSuccess(a: Admin): Admin {
  return { ...a, failedAttempts: 0, lockedUntil: null };
}

/** A passphrase-length password with letters and at least one other kind of character. */
export function isStrongPassword(pw: string): boolean {
  const length = pw.replace(/[\uD800-\uDBFF][\uDC00-\uDFFF]/g, '_').length;
  return length >= MIN_PASSWORD_LENGTH && /\p{L}/u.test(pw) && /[^\p{L}]/u.test(pw);
}
