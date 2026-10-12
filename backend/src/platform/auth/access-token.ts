import { type KeyObject } from 'node:crypto';
import { errors, jwtVerify, type JWTPayload, type ProtectedHeaderParameters, SignJWT } from 'jose';
import { NIL as NIL_UUID, validate as isUuid } from 'uuid';
import { type Clock } from '../clock/clock';
import { type IdGenerator } from '../ids/id-generator';

/** The claims of an access token (02-architecture §5). */
export interface AccessClaims {
  readonly subject: string;
  readonly roles: readonly string[];
  /** The token id (`jti`), used by the denylist. */
  readonly tokenId: string;
  /** The refresh-token family (device) the token belongs to (`sid`). */
  readonly sessionId: string;
  /** The RBAC version the roles were read at (`ver`). */
  readonly version: number;
  readonly expiresAt: Date;
}

/** What the caller decides when signing; the signer fills in the id and expiry. */
export interface TokenRequest {
  readonly subject: string;
  readonly roles: readonly string[];
  readonly sessionId?: string;
  readonly version?: number;
}

/** Thrown for a token whose expiry has passed; the API answers TOKEN_EXPIRED. */
export class TokenExpiredError extends Error {
  constructor() {
    super('access token expired');
    this.name = 'TokenExpiredError';
  }
}

/** Thrown for a token that is forged, malformed or signed by an unknown key. */
export class TokenInvalidError extends Error {
  constructor(cause?: unknown) {
    super('access token invalid', { cause });
    this.name = 'TokenInvalidError';
  }
}

const seconds = (d: Date): number => Math.floor(d.getTime() / 1000);

/** The current signing key and how long its tokens live (15 minutes in production). */
export interface SigningKey {
  readonly keyId: string;
  readonly key: KeyObject;
  readonly ttlMs: number;
}

/** Issues EdDSA access tokens with the current key. */
export class TokenSigner {
  constructor(
    private readonly signing: SigningKey,
    private readonly clock: Clock,
    private readonly ids: IdGenerator,
  ) {}

  /** Signs a token and returns it with the claims it carries. */
  async sign(req: TokenRequest): Promise<{ token: string; claims: AccessClaims }> {
    const now = this.clock.now();
    const claims: AccessClaims = {
      subject: req.subject,
      roles: [...req.roles],
      tokenId: this.ids.newId(),
      sessionId: req.sessionId ?? NIL_UUID,
      version: req.version ?? 0,
      expiresAt: new Date(now.getTime() + this.signing.ttlMs),
    };
    const payload = {
      roles: claims.roles,
      ver: claims.version,
      sid: claims.sessionId,
      iss: 'pao',
      sub: claims.subject,
      exp: seconds(claims.expiresAt),
      iat: seconds(now),
      jti: claims.tokenId,
    };
    try {
      const token = await new SignJWT(payload)
        .setProtectedHeader({ alg: 'EdDSA', kid: this.signing.keyId, typ: 'JWT' })
        .sign(this.signing.key);
      return { token, claims };
    } catch (cause) {
      throw new Error('sign access token', { cause });
    }
  }
}

const isStringList = (v: unknown): v is string[] =>
  Array.isArray(v) && v.every((r) => typeof r === 'string');

const isUuidText = (v: unknown): v is string => typeof v === 'string' && isUuid(v);

function toClaims(p: JWTPayload): AccessClaims {
  const { sub, jti, exp, roles, ver } = p;
  const sessionId = p.sid ?? NIL_UUID;
  if (!isUuidText(sub) || !isStringList(roles) || !isUuidText(sessionId)) {
    throw new TokenInvalidError();
  }
  return {
    subject: sub,
    roles,
    tokenId: typeof jti === 'string' ? jti : '',
    sessionId,
    version: typeof ver === 'number' ? ver : 0,
    expiresAt: new Date((exp ?? 0) * 1000),
  };
}

/**
 * Checks tokens against the current and previous public keys (kid → key), so keys can
 * rotate without signing everyone out.
 */
export class TokenVerifier {
  constructor(
    private readonly keys: ReadonlyMap<string, KeyObject>,
    private readonly clock: Clock,
  ) {}

  /** Returns the token's claims or throws {@link TokenExpiredError} / {@link TokenInvalidError}. */
  async verify(token: string): Promise<AccessClaims> {
    let payload: JWTPayload;
    try {
      ({ payload } = await jwtVerify(token, (header) => this.key(header), {
        algorithms: ['EdDSA'],
        issuer: 'pao',
        requiredClaims: ['exp'],
        currentDate: this.clock.now(),
      }));
    } catch (err) {
      throw err instanceof errors.JWTExpired ? new TokenExpiredError() : new TokenInvalidError(err);
    }
    return toClaims(payload);
  }

  private key(header: ProtectedHeaderParameters): KeyObject {
    const key = header.kid === undefined ? undefined : this.keys.get(header.kid);
    if (!key) {
      throw new Error(`unknown key id ${JSON.stringify(header.kid)}`);
    }
    return key;
  }
}
