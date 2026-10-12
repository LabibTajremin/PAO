import { type IdentityReason, IdentityReasons } from './reasons';

/** Digits in a one-time code (docs/build/02-architecture.md §5). */
export const CODE_LENGTH = 6;
/** How long a code stays valid. */
export const CODE_TTL_MS = 5 * 60_000;
/** Wrong guesses allowed before the code is discarded. */
export const CODE_MAX_ATTEMPTS = 5;
/** The wait between two codes to one phone. */
export const RESEND_AFTER_MS = 60_000;

/** The send windows that throttle SMS cost and brute force. */
export const SEND_LIMITS = {
  perPhone: { limit: 3, windowMs: 15 * 60_000 },
  perIp: { limit: 10, windowMs: 60 * 60_000 },
} as const;

/** A sent code as kept in Redis: only its hash and the attempts so far. */
export interface StoredCode {
  readonly hash: string;
  readonly attempts: number;
}

/** The outcome of one guess: whether to drop the stored code, and why it failed. */
export interface Attempt {
  readonly discard: boolean;
  readonly refusal?: IdentityReason;
}

/** Applies a guess; `matched` says whether its hash matched. */
export function checkAttempt(code: StoredCode, matched: boolean): Attempt {
  if (matched) {
    return { discard: true };
  }
  if (code.attempts + 1 >= CODE_MAX_ATTEMPTS) {
    return { discard: true, refusal: IdentityReasons.CodeLocked };
  }
  return { discard: false, refusal: IdentityReasons.CodeInvalid };
}
