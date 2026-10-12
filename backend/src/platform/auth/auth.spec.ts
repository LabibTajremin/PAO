import { generateKeyPairSync, sign } from 'node:crypto';
import { Test } from '@nestjs/testing';
import { SignJWT } from 'jose';
import { v4 as uuidv4 } from 'uuid';
import { FakeClock } from '../clock/fake-clock';
import { loadConfig } from '../config/load-config';
import { ConfigModule } from '../config/config.module';
import { UuidV7Generator } from '../ids/id-generator';
import { RuntimeModule } from '../runtime.module';
import { TokenExpiredError, TokenInvalidError, TokenSigner, TokenVerifier } from './access-token';
import { AuthModule } from './auth.module';
import { CiphertextError, DataCipher } from './data-cipher';
import { privateKeyFromSeed, publicKeyFromRaw, publicKeyOf, rawPublicKey } from './ed25519';
import {
  CODE_PARAMS,
  hashSecret,
  HashMalformedError,
  PASSWORD_PARAMS,
  verifySecret,
} from './password-hash';
import { randomDigits, randomToken, sha256Hex } from './random';
import { newTotpSecret, totpCode, validateTotp } from './totp';

const ids = new UuidV7Generator();

function seed(first: number): Buffer {
  const s = Buffer.alloc(32);
  s[0] = first;
  return s;
}

// The exact header and claims bytes golang-jwt wrote for the Go backend (seed[0]=1).
// Ed25519 signatures are deterministic, so signing them here yields Go's token.
const GO_HEADER = '{"alg":"EdDSA","kid":"k1","typ":"JWT"}';
const GO_CLAIMS =
  '{"exp":1893456000,"iat":1767225600,"iss":"pao","jti":"j1","roles":["customer"],' +
  '"sid":"0199c4f0-0000-7000-8000-000000000002","sub":"0199c4f0-0000-7000-8000-000000000001","ver":3}';

function goToken(): string {
  const encode = (text: string): string => Buffer.from(text).toString('base64url');
  const input = `${encode(GO_HEADER)}.${encode(GO_CLAIMS)}`;
  const signature = sign(null, Buffer.from(input), privateKeyFromSeed(seed(1)));
  return `${input}.${signature.toString('base64url')}`;
}

// Produced by the Go backend (x/crypto/argon2, crypto/cipher).
const GO_HASH =
  '$argon2id$v=19$m=8192,t=1,p=1$MDEyMzQ1Njc4OWFiY2RlZg$3lBpVtezkCtsfJ9k4OjuMyXHCGqJpPGTwvQcAZzUTsA';
const GO_CIPHERTEXT =
  '000000000000000000000000ff95730978565c563e7ef413d0438ce0ca54d98e127254dff187';

describe('access tokens', () => {
  const clock = new FakeClock(new Date('2026-10-09T10:00:00Z'));
  const oldKey = privateKeyFromSeed(seed(1));
  const newKey = privateKeyFromSeed(seed(2));
  const verifier = new TokenVerifier(
    new Map([
      ['k1', publicKeyOf(oldKey)],
      ['k2', publicKeyOf(newKey)],
    ]),
    clock,
  );

  it('verifies tokens of the current and previous keys', async () => {
    const subject = uuidv4();
    const sessionId = uuidv4();
    for (const [kid, key] of [
      ['k1', oldKey],
      ['k2', newKey],
    ] as const) {
      const signer = new TokenSigner({ keyId: kid, key, ttlMs: 15 * 60_000 }, clock, ids);
      const { token, claims } = await signer.sign({
        subject,
        roles: ['customer'],
        version: 3,
        sessionId,
      });
      const got = await verifier.verify(token);
      expect(got).toEqual({ ...claims, expiresAt: new Date('2026-10-09T10:15:00Z') });
      expect(got.roles).toEqual(['customer']);
    }
  });

  it('expires tokens and fills defaults', async () => {
    const signer = new TokenSigner({ keyId: 'k2', key: newKey, ttlMs: 15 * 60_000 }, clock, ids);
    const { token, claims } = await signer.sign({ subject: uuidv4(), roles: [] });
    expect(claims.sessionId).toBe('00000000-0000-0000-0000-000000000000');
    expect(claims.version).toBe(0);
    const later = new TokenVerifier(
      new Map([['k2', publicKeyOf(newKey)]]),
      new FakeClock(new Date('2026-10-09T10:16:00Z')),
    );
    await expect(later.verify(token)).rejects.toBeInstanceOf(TokenExpiredError);
  });

  it('accepts tokens the Go backend signed', async () => {
    const got = await verifier.verify(goToken());
    expect(got).toEqual({
      subject: '0199c4f0-0000-7000-8000-000000000001',
      roles: ['customer'],
      tokenId: 'j1',
      sessionId: '0199c4f0-0000-7000-8000-000000000002',
      version: 3,
      expiresAt: new Date('2030-01-01T00:00:00Z'),
    });
  });

  it('rejects forged, unknown and malformed tokens', async () => {
    const attacker = privateKeyFromSeed(seed(9));
    const forged = await new TokenSigner(
      { keyId: 'k1', key: attacker, ttlMs: 60_000 },
      clock,
      ids,
    ).sign({
      subject: uuidv4(),
      roles: [],
    });
    const unknownKid = await new TokenSigner(
      { keyId: 'k9', key: attacker, ttlMs: 60_000 },
      clock,
      ids,
    ).sign({
      subject: uuidv4(),
      roles: [],
    });
    const custom = (claims: Record<string, unknown>, kid?: string) =>
      new SignJWT({ iss: 'pao', exp: 1_900_000_000, ...claims })
        .setProtectedHeader(kid === undefined ? { alg: 'EdDSA' } : { alg: 'EdDSA', kid })
        .sign(oldKey);
    const tokens = [
      forged.token,
      unknownKid.token,
      'a.b.c',
      await custom({ sub: 'not-a-uuid', roles: [] }, 'k1'),
      await custom({ sub: uuidv4(), roles: 'admin' }, 'k1'),
      await custom({ sub: uuidv4(), roles: [], sid: 'nope' }, 'k1'),
      await custom({ sub: uuidv4(), roles: [] }),
    ];
    for (const token of tokens) {
      await expect(verifier.verify(token)).rejects.toBeInstanceOf(TokenInvalidError);
    }
    const minimal = await verifier.verify(await custom({ sub: uuidv4(), roles: [] }, 'k1'));
    expect(minimal).toMatchObject({ tokenId: '', version: 0 });
  });

  it('reports a key that cannot sign', async () => {
    const { privateKey } = generateKeyPairSync('rsa', { modulusLength: 1024 });
    const signer = new TokenSigner({ keyId: 'k1', key: privateKey, ttlMs: 60_000 }, clock, ids);
    await expect(signer.sign({ subject: uuidv4(), roles: [] })).rejects.toThrow(
      'sign access token',
    );
  });

  it('round-trips raw Ed25519 public keys', () => {
    const pub = publicKeyOf(oldKey);
    expect(publicKeyFromRaw(rawPublicKey(pub)).equals(pub)).toBe(true);
  });
});

describe('argon2id hashing', () => {
  it('verifies, rejects and accepts Go hashes', async () => {
    const h = await hashSecret('correct-horse', CODE_PARAMS);
    expect(await verifySecret('correct-horse', h)).toBe(true);
    expect(await verifySecret('wrong', h)).toBe(false);
    expect(await verifySecret('correct-horse', GO_HASH)).toBe(true);
    expect(await hashSecret('x', PASSWORD_PARAMS)).toMatch(/^\$argon2id\$v=19\$m=65536,t=3,p=2\$/);
  });

  it.each([
    'plain',
    '$bcrypt$x$y$z$w',
    '$argon2id$v=19$bad$MDEyMzQ1Njc4OWFiY2RlZg$3lBpVtezkCtsfJ9k4OjuMyXHCGqJpPGTwvQcAZzUTsA',
    '$argon2id$v=19$m=8192,t=1,p=1$!!$3lBpVtezkCtsfJ9k4OjuMyXHCGqJpPGTwvQcAZzUTsA',
  ])('rejects malformed hash %s', async (bad) => {
    await expect(verifySecret('x', bad)).rejects.toBeInstanceOf(HashMalformedError);
  });
});

describe('DataCipher', () => {
  it('encrypts, detects tampering and hashes for lookups', () => {
    const c = new DataCipher(Buffer.alloc(32));
    const enc = c.encrypt(Buffer.from('1234567890'));
    expect(enc.includes(Buffer.from('1234567890'))).toBe(false);
    expect(c.decrypt(enc).toString()).toBe('1234567890');
    expect(c.decrypt(Buffer.from(GO_CIPHERTEXT, 'hex')).toString()).toBe('1234567890');
    enc[enc.length - 1] = (enc[enc.length - 1] ?? 0) ^ 1;
    expect(() => c.decrypt(enc)).toThrow(CiphertextError);
    expect(() => c.decrypt(Buffer.from([1]))).toThrow(CiphertextError);
    expect(c.lookupHash('a')).toBe(c.lookupHash('a'));
    expect(c.lookupHash('a')).not.toBe(c.lookupHash('b'));
    expect(
      new DataCipher(Buffer.alloc(16))
        .decrypt(new DataCipher(Buffer.alloc(16)).encrypt(Buffer.from('x')))
        .toString(),
    ).toBe('x');
    expect(() => new DataCipher(Buffer.from('short'))).toThrow('invalid key size');
  });
});

describe('random values', () => {
  it('draws digits, tokens and hashes', () => {
    expect(randomDigits(6)).toMatch(/^\d{6}$/);
    const a = randomToken(32);
    expect(a).toHaveLength(43);
    expect(a).not.toBe(randomToken(32));
    expect(sha256Hex('a')).toBe('ca978112ca1bbdcafac231b39a23dc4da786eff8147c4e72b9807785afee48bb');
  });
});

describe('TOTP', () => {
  it('enrols, generates and validates with one step of drift', async () => {
    const { secret, url } = newTotpSecret('verifier@pao.bd');
    expect(url.startsWith('otpauth://totp/PAO:verifier@pao.bd?algorithm=SHA1&digits=6')).toBe(true);
    expect(url).toContain('issuer=PAO&period=30&secret=' + secret);
    const now = new Date('2026-10-09T10:00:00Z');
    const code = await totpCode(secret, now);
    expect(await validateTotp(code, secret, new Date(now.getTime() + 25_000))).toBe(true);
    expect(await validateTotp(code, secret, new Date(now.getTime() + 5 * 60_000))).toBe(false);
    expect(await validateTotp('000000', '!!', now)).toBe(false);
    expect(() => newTotpSecret('')).toThrow('account name is required');
  });
});

describe('AuthModule', () => {
  it('builds the signer, the verifier and the cipher from the configuration', async () => {
    const config = loadConfig({
      DATABASE_URL: 'postgres://x',
      REDIS_URL: 'redis://x',
      S3_ENDPOINT: 'http://s3',
      S3_ACCESS_KEY: 'a',
      S3_SECRET_KEY: 'b',
      S3_BUCKET_PRIVATE: 'p',
      S3_BUCKET_PUBLIC: 'q',
      JWT_SIGNING_KEY: seed(2).toString('base64'),
      JWT_KEY_ID: 'k2',
      JWT_PREVIOUS_PUBLIC_KEYS:
        'k1:' + rawPublicKey(publicKeyOf(privateKeyFromSeed(seed(1)))).toString('base64'),
      DATA_ENCRYPTION_KEY: Buffer.alloc(32).toString('base64'),
    });
    const ref = await Test.createTestingModule({
      imports: [ConfigModule.forRoot(config), RuntimeModule, AuthModule],
    }).compile();
    const signed = await ref.get(TokenSigner).sign({ subject: uuidv4(), roles: ['customer'] });
    const verifier = ref.get(TokenVerifier);
    expect((await verifier.verify(signed.token)).roles).toEqual(['customer']);
    expect(signed.claims.expiresAt.getTime() - Date.now()).toBeGreaterThan(14 * 60_000);
    await expect(verifier.verify(goToken())).resolves.toMatchObject({ version: 3 });
    expect(ref.get(DataCipher).decrypt(Buffer.from(GO_CIPHERTEXT, 'hex')).toString()).toBe(
      '1234567890',
    );
  });
});
