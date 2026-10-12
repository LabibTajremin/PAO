import { Inject, Injectable } from '@nestjs/common';
import { randomToken, sha256Hex } from '../../../platform/auth/random';
import { DomainError, isDomainError } from '../../../platform/errors/domain-error';
import { ID_GENERATOR, type IdGenerator } from '../../../platform/ids/id-generator';
import { type Account, signInRefusal } from '../domain/account';
import { IdentityReasons } from '../domain/reasons';
import {
  ACCESS_TTL_MS,
  type Family,
  familyMatches,
  formatRefreshToken,
  parseRefreshToken,
  REFRESH_TTL_MS,
} from '../domain/session';
import { IDENTITY_REPOSITORY, type IdentityRepository } from '../port/identity-repository';
import { AccessTokens } from './access-tokens';
import { SESSION_STORE, type SessionStore } from '../port/short-lived-state';

/** What a successful sign-in or refresh returns. */
export interface Session {
  readonly accessToken: string;
  readonly refreshToken: string;
  readonly expiresInMs: number;
  readonly account: Account;
  readonly isNewAccount: boolean;
}

/** The signed-in device making a request. */
export interface Caller {
  readonly accountId: string;
  readonly sessionId: string;
  readonly tokenId: string;
  readonly expiresAt: Date;
}

/**
 * Sessions are refresh-token families in Redis with short-lived access tokens; ending
 * one also denylists its live access token (docs/build/02-architecture.md §5).
 */
@Injectable()
export class Sessions {
  constructor(
    @Inject(IDENTITY_REPOSITORY) private readonly repo: IdentityRepository,
    @Inject(SESSION_STORE) private readonly families: SessionStore,
    @Inject(AccessTokens) private readonly tokens: AccessTokens,
    @Inject(ID_GENERATOR) private readonly ids: IdGenerator,
  ) {}

  /** Starts a new refresh-token family for the device. */
  open(a: Account, app: string, isNewAccount = false): Promise<Session> {
    const family = {
      id: this.ids.newId(),
      accountId: a.id,
      app,
      currentHash: '',
      accessTokenId: '',
      accessExpiresAt: new Date(0),
    };
    return this.issue(a, family, isNewAccount);
  }

  /**
   * Exchanges a refresh token for a new pair. Presenting an already rotated token
   * revokes the whole family: someone else has a copy.
   */
  async refresh(token: string): Promise<Session> {
    const parsed = parseRefreshToken(token);
    if (!parsed) {
      throw new DomainError(IdentityReasons.RefreshInvalid);
    }
    const family = await this.families.get(parsed.familyId);
    if (!familyMatches(family, sha256Hex(parsed.secret))) {
      return this.endRefusing(family, IdentityReasons.RefreshReused);
    }
    const account = await this.repo.accountById(family.accountId);
    const refusal = signInRefusal(account);
    if (refusal) {
      return this.endRefusing(family, refusal);
    }
    return this.issue(account, family, false);
  }

  /** Ends the family and refuses; a failure to end it rides along as the cause. */
  private async endRefusing(family: Family, reason: string): Promise<never> {
    let cause: unknown;
    await this.end(family).catch((err: unknown) => (cause = err));
    throw new DomainError(reason, { cause });
  }

  /** Ends the caller's session, or every session of the account. */
  async logout(c: Caller, allDevices: boolean): Promise<void> {
    await this.tokens.revoke(c.tokenId, c.expiresAt);
    if (allDevices) {
      await this.revokeAll(c.accountId);
      return;
    }
    let family: Family;
    try {
      family = await this.families.get(c.sessionId);
    } catch (err) {
      if (isDomainError(err, IdentityReasons.RefreshInvalid)) {
        return;
      }
      throw err;
    }
    await this.end(family);
  }

  /** Ends every session of an account (ban, suspension, deletion, role change). */
  async revokeAll(accountId: string): Promise<void> {
    for (const family of await this.families.listForAccount(accountId)) {
      await this.end(family);
    }
  }

  private async issue(a: Account, f: Family, isNewAccount: boolean): Promise<Session> {
    const { token, claims } = await this.tokens.sign(a, f.id);
    const secret = randomToken(32);
    const rotated = {
      ...f,
      currentHash: sha256Hex(secret),
      accessTokenId: claims.tokenId,
      accessExpiresAt: claims.expiresAt,
    };
    await this.families.save(rotated, REFRESH_TTL_MS);
    return {
      accessToken: token,
      refreshToken: formatRefreshToken(f.id, secret),
      expiresInMs: ACCESS_TTL_MS,
      account: a,
      isNewAccount,
    };
  }

  private async end(f: Family): Promise<void> {
    await this.tokens.revoke(f.accessTokenId, f.accessExpiresAt);
    await this.families.delete(f);
  }
}
