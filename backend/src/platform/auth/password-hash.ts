import { randomBytes, timingSafeEqual } from 'node:crypto';
import { hash, hashRaw } from '@node-rs/argon2';

/** argon2id cost settings. */
export interface Argon2Params {
  /** Memory in KiB. */
  readonly memory: number;
  readonly time: number;
  readonly threads: number;
}

/** Passwords: the OWASP-recommended cost the Go backend used. */
export const PASSWORD_PARAMS: Argon2Params = { memory: 64 * 1024, time: 3, threads: 2 };

/** One-time codes live five minutes and allow five attempts, so a cheaper cost is enough. */
export const CODE_PARAMS: Argon2Params = { memory: 8 * 1024, time: 1, threads: 1 };

/** Thrown for a stored hash in an unknown format. */
export class HashMalformedError extends Error {
  constructor() {
    super('password hash malformed');
    this.name = 'HashMalformedError';
  }
}

// @node-rs/argon2 defaults to argon2id, version 0x13, as Go's x/crypto/argon2.IDKey.

/** Returns a PHC-encoded argon2id hash (`$argon2id$v=19$m=…,t=…,p=…$salt$key`) of `secret`. */
export function hashSecret(secret: string, p: Argon2Params): Promise<string> {
  return hash(secret, {
    memoryCost: p.memory,
    timeCost: p.time,
    parallelism: p.threads,
    outputLen: 32,
    salt: randomBytes(16),
  });
}

function decodeRawBase64(text: string): Buffer | undefined {
  return /^[A-Za-z0-9+/]+$/.test(text) ? Buffer.from(text, 'base64') : undefined;
}

/**
 * Reports whether `secret` matches `encoded`, comparing in constant time. Accepts the
 * hashes the Go backend stored.
 */
export async function verifySecret(secret: string, encoded: string): Promise<boolean> {
  const parts = encoded.split('$');
  const params = /^m=(\d+),t=(\d+),p=(\d+)$/.exec(parts[3] ?? '');
  const salt = decodeRawBase64(parts[4] ?? '');
  const want = decodeRawBase64(parts[5] ?? '');
  if (parts.length !== 6 || parts[1] !== 'argon2id' || !params || !salt || !want) {
    throw new HashMalformedError();
  }
  const got = await hashRaw(secret, {
    memoryCost: Number(params[1]),
    timeCost: Number(params[2]),
    parallelism: Number(params[3]),
    outputLen: want.length,
    salt,
  });
  return timingSafeEqual(got, want);
}
