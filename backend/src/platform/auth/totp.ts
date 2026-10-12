import { generate, generateSecret, verify } from 'otplib';

const PERIOD_SECONDS = 30;

/** A new admin TOTP secret and the otpauth:// URL their authenticator app scans (A-01). */
export interface TotpEnrolment {
  readonly secret: string;
  readonly url: string;
}

/** Creates a TOTP secret (20 random bytes, base32) for `account`. */
export function newTotpSecret(account: string): TotpEnrolment {
  if (account === '') {
    throw new Error('generate totp secret: account name is required');
  }
  const secret = generateSecret();
  const label = encodeURIComponent(`PAO:${account}`).replaceAll('%3A', ':').replaceAll('%40', '@');
  const query = new URLSearchParams({
    algorithm: 'SHA1',
    digits: '6',
    issuer: 'PAO',
    period: String(PERIOD_SECONDS),
    secret,
  });
  return { secret, url: `otpauth://totp/${label}?${query.toString()}` };
}

const epochSeconds = (at: Date): number => Math.floor(at.getTime() / 1000);

/**
 * Checks a 6-digit code at `now`, allowing one 30-second step of clock drift either way.
 * A malformed secret or code is simply not valid.
 */
export async function validateTotp(code: string, secret: string, now: Date): Promise<boolean> {
  try {
    const result = await verify({
      secret,
      token: code,
      epoch: epochSeconds(now),
      epochTolerance: PERIOD_SECONDS,
    });
    return result.valid;
  } catch {
    return false;
  }
}

/** Returns the code for `secret` at `now`; used by tests and the e2e suite. */
export function totpCode(secret: string, now: Date): Promise<string> {
  return generate({ secret, epoch: epochSeconds(now) });
}
