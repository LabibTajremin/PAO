import { type Challenge } from '../domain/admin';
import { type StoredCode } from '../domain/code';
import { type Family } from '../domain/session';

/** Hashed one-time codes per purpose and phone; a missing code throws CodeExpired. */
export interface CodeStore {
  save(purpose: string, phone: string, code: StoredCode): Promise<void>;
  get(purpose: string, phone: string): Promise<StoredCode>;
  incrementAttempts(purpose: string, phone: string): Promise<void>;
  delete(purpose: string, phone: string): Promise<void>;
}

/** Injection token for the {@link CodeStore}. */
export const CODE_STORE = Symbol('CodeStore');

/**
 * The windows on sending codes: the resend timer and the per-phone and per-IP limits.
 * Returns 0 when a send is allowed, else how long to wait in milliseconds.
 */
export interface SendThrottle {
  retryAfterMs(phone: string, clientIp: string | undefined): Promise<number>;
}

/** Injection token for the {@link SendThrottle}. */
export const SEND_THROTTLE = Symbol('SendThrottle');

/**
 * Refresh-token families (`rt:{familyId}`, indexed by `sess:{accountId}`); a missing
 * family throws RefreshInvalid.
 */
export interface SessionStore {
  save(f: Family, ttlMs: number): Promise<void>;
  get(familyId: string): Promise<Family>;
  delete(f: Family): Promise<void>;
  listForAccount(accountId: string): Promise<Family[]>;
}

/** Injection token for the {@link SessionStore}. */
export const SESSION_STORE = Symbol('SessionStore');

/** Pending admin 2FA logins (`mfa:{id}`); a missing one throws ChallengeExpired. */
export interface ChallengeStore {
  save(c: Challenge, ttlMs: number): Promise<void>;
  get(id: string): Promise<Challenge>;
  delete(id: string): Promise<void>;
}

/** Injection token for the {@link ChallengeStore}. */
export const CHALLENGE_STORE = Symbol('ChallengeStore');
