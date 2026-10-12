import { createHash, randomBytes, randomInt } from 'node:crypto';

/** Returns a URL-safe token with `bytes` bytes of entropy (refresh tokens use 32). */
export function randomToken(bytes: number): string {
  return randomBytes(bytes).toString('base64url');
}

/** Returns `n` decimal digits from the CSPRNG (OTPs, start codes). */
export function randomDigits(n: number): string {
  let digits = '';
  for (let i = 0; i < n; i++) {
    digits += String(randomInt(10));
  }
  return digits;
}

/** Hashes a high-entropy token for storage; low-entropy secrets use argon2id instead. */
export function sha256Hex(value: string): string {
  return createHash('sha256').update(value).digest('hex');
}
