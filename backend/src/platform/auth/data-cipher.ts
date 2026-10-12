import {
  type CipherGCMTypes,
  createCipheriv,
  createDecipheriv,
  createHmac,
  randomBytes,
} from 'node:crypto';

const NONCE_BYTES = 12;
const TAG_BYTES = 16;

/** Thrown for data that this key did not produce. */
export class CiphertextError extends Error {
  constructor() {
    super('ciphertext invalid');
    this.name = 'CiphertextError';
  }
}

/**
 * Encrypts sensitive fields (NID numbers, TOTP secrets) with AES-GCM as `nonce ‖
 * ciphertext ‖ tag`, the layout Go's cipher.AEAD.Seal produced, and derives keyed lookup
 * hashes so equal values can be found without decrypting.
 */
export class DataCipher {
  private readonly algorithm: CipherGCMTypes;
  private readonly macKey: Buffer;

  constructor(private readonly key: Buffer) {
    if (![16, 24, 32].includes(key.length)) {
      throw new Error(`data key: invalid key size ${key.length}`);
    }
    this.algorithm = `aes-${key.length * 8}-gcm` as CipherGCMTypes;
    this.macKey = createHmac('sha256', key).update('pao-lookup-hash').digest();
  }

  /** Returns nonce ‖ ciphertext ‖ tag. */
  encrypt(plaintext: Buffer): Buffer {
    const nonce = randomBytes(NONCE_BYTES);
    const cipher = createCipheriv(this.algorithm, this.key, nonce);
    const body = Buffer.concat([cipher.update(plaintext), cipher.final()]);
    return Buffer.concat([nonce, body, cipher.getAuthTag()]);
  }

  /** Reverses {@link encrypt}; throws {@link CiphertextError} for anything else. */
  decrypt(data: Buffer): Buffer {
    if (data.length < NONCE_BYTES + TAG_BYTES) {
      throw new CiphertextError();
    }
    const decipher = createDecipheriv(this.algorithm, this.key, data.subarray(0, NONCE_BYTES));
    decipher.setAuthTag(data.subarray(data.length - TAG_BYTES));
    try {
      const body = data.subarray(NONCE_BYTES, data.length - TAG_BYTES);
      return Buffer.concat([decipher.update(body), decipher.final()]);
    } catch {
      throw new CiphertextError();
    }
  }

  /** Returns a keyed hash of `value` for equality lookups. */
  lookupHash(value: string): string {
    return createHmac('sha256', this.macKey).update(value).digest('hex');
  }
}
