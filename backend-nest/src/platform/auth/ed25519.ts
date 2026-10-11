import { createPrivateKey, createPublicKey, type KeyObject } from 'node:crypto';

// DER prefixes that wrap a raw Ed25519 seed (PKCS#8) or public key (SPKI), so keys kept
// in the environment as base64 bytes, as Go's crypto/ed25519 reads them, load unchanged.
const PKCS8_PREFIX = Buffer.from('302e020100300506032b657004220420', 'hex');
const SPKI_PREFIX = Buffer.from('302a300506032b6570032100', 'hex');

/** Size in bytes of an Ed25519 seed and of a raw Ed25519 public key. */
export const ED25519_KEY_BYTES = 32;

/** Builds the Ed25519 private key for a 32-byte seed. */
export function privateKeyFromSeed(seed: Buffer): KeyObject {
  return createPrivateKey({
    key: Buffer.concat([PKCS8_PREFIX, seed]),
    format: 'der',
    type: 'pkcs8',
  });
}

/** Builds the Ed25519 public key for its 32 raw bytes. */
export function publicKeyFromRaw(raw: Buffer): KeyObject {
  return createPublicKey({ key: Buffer.concat([SPKI_PREFIX, raw]), format: 'der', type: 'spki' });
}

/** Returns the public half of an Ed25519 private key. */
export function publicKeyOf(privateKey: KeyObject): KeyObject {
  return createPublicKey(privateKey);
}

/** Returns the 32 raw bytes of an Ed25519 public key. */
export function rawPublicKey(publicKey: KeyObject): Buffer {
  return publicKey.export({ format: 'der', type: 'spki' }).subarray(SPKI_PREFIX.length);
}
