// Identity's short-lived state in Redis: one-time codes, refresh-token families and
// admin login challenges, in the Go backend's layout (docs/build/02-architecture.md §4).
import { Inject, Injectable } from '@nestjs/common';
import type Redis from 'ioredis';
import { DomainError } from '../../../../platform/errors/domain-error';
import { RateLimiter } from '../../../../platform/redis/rate-limiter';
import { REDIS, REDIS_KEYS, type RedisKeys } from '../../../../platform/redis/redis-client';
import { type Challenge } from '../../domain/admin';
import { CODE_TTL_MS, RESEND_AFTER_MS, SEND_LIMITS, type StoredCode } from '../../domain/code';
import { IdentityReasons } from '../../domain/reasons';
import { type Family } from '../../domain/session';
import {
  type ChallengeStore,
  type CodeStore,
  type SendThrottle,
  type SessionStore,
} from '../../port/short-lived-state';

/** Codes as hashes `otp:{purpose}:{phone}` = `{h: hash, a: attempts}`. */
@Injectable()
export class RedisCodeStore implements CodeStore {
  constructor(
    @Inject(REDIS) private readonly redis: Redis,
    @Inject(REDIS_KEYS) private readonly keys: RedisKeys,
  ) {}

  async save(purpose: string, phone: string, code: StoredCode): Promise<void> {
    const key = this.key(purpose, phone);
    await this.redis
      .multi()
      .del(key)
      .hset(key, 'h', code.hash, 'a', code.attempts)
      .pexpire(key, CODE_TTL_MS)
      .exec();
  }

  async get(purpose: string, phone: string): Promise<StoredCode> {
    const m = await this.redis.hgetall(this.key(purpose, phone));
    if (!m.h) {
      throw new DomainError(IdentityReasons.CodeExpired);
    }
    return { hash: m.h, attempts: Number(m.a ?? 0) };
  }

  async incrementAttempts(purpose: string, phone: string): Promise<void> {
    await this.redis.hincrby(this.key(purpose, phone), 'a', 1);
  }

  async delete(purpose: string, phone: string): Promise<void> {
    await this.redis.del(this.key(purpose, phone));
  }

  private key(purpose: string, phone: string): string {
    return this.keys.key('otp', purpose, phone);
  }
}

/**
 * The send windows as sliding-window limits: `rl:otp:resend:{phone}`,
 * `rl:otp:phone:{phone}` and, for app requests, `rl:otp:ip:{ip}`.
 */
@Injectable()
export class RedisSendThrottle implements SendThrottle {
  constructor(
    @Inject(RateLimiter) private readonly limiter: RateLimiter,
    @Inject(REDIS_KEYS) private readonly keys: RedisKeys,
  ) {}

  async retryAfterMs(phone: string, clientIp: string | undefined): Promise<number> {
    const windows = [
      { key: this.keys.key('rl', 'otp', 'resend', phone), limit: 1, windowMs: RESEND_AFTER_MS },
      { key: this.keys.key('rl', 'otp', 'phone', phone), ...SEND_LIMITS.perPhone },
    ];
    if (clientIp !== undefined && clientIp !== '') {
      windows.push({ key: this.keys.key('rl', 'otp', 'ip', clientIp), ...SEND_LIMITS.perIp });
    }
    for (const w of windows) {
      const decision = await this.limiter.allow(w.key, w.limit, w.windowMs);
      if (!decision.allowed) {
        return decision.retryAfterMs;
      }
    }
    return 0;
  }
}

/** Families as hashes `rt:{familyId}`, indexed by the set `sess:{accountId}`. */
@Injectable()
export class RedisSessionStore implements SessionStore {
  constructor(
    @Inject(REDIS) private readonly redis: Redis,
    @Inject(REDIS_KEYS) private readonly keys: RedisKeys,
  ) {}

  async save(f: Family, ttlMs: number): Promise<void> {
    const family = this.familyKey(f.id);
    const account = this.accountKey(f.accountId);
    await this.redis
      .multi()
      .hset(family, {
        account: f.accountId,
        app: f.app,
        hash: f.currentHash,
        jti: f.accessTokenId,
        exp: f.accessExpiresAt.getTime(),
      })
      .pexpire(family, ttlMs)
      .sadd(account, f.id)
      .pexpire(account, ttlMs)
      .exec();
  }

  async get(familyId: string): Promise<Family> {
    const m = await this.redis.hgetall(this.familyKey(familyId));
    if (!m.account) {
      throw new DomainError(IdentityReasons.RefreshInvalid);
    }
    return {
      id: familyId,
      accountId: m.account,
      app: m.app ?? '',
      currentHash: m.hash ?? '',
      accessTokenId: m.jti ?? '',
      accessExpiresAt: new Date(Number(m.exp ?? 0)),
    };
  }

  async delete(f: Family): Promise<void> {
    await this.redis
      .multi()
      .del(this.familyKey(f.id))
      .srem(this.accountKey(f.accountId), f.id)
      .exec();
  }

  /** The account's live families; index entries whose family expired are dropped. */
  async listForAccount(accountId: string): Promise<Family[]> {
    const families: Family[] = [];
    for (const id of await this.redis.smembers(this.accountKey(accountId))) {
      const family = await this.get(id).catch((err: unknown) => {
        if (err instanceof DomainError) {
          return undefined;
        }
        throw err;
      });
      if (family) {
        families.push(family);
      } else {
        await this.redis.srem(this.accountKey(accountId), id);
      }
    }
    return families;
  }

  private familyKey(id: string): string {
    return this.keys.key('rt', id);
  }

  private accountKey(id: string): string {
    return this.keys.key('sess', id);
  }
}

/** The JSON the Go backend stored under `mfa:{id}`. */
interface StoredChallenge {
  ID: string;
  AdminID: string;
  Attempts: number;
  EnrolSecret: string;
}

/** Challenges as JSON strings `mfa:{id}`. */
@Injectable()
export class RedisChallengeStore implements ChallengeStore {
  constructor(
    @Inject(REDIS) private readonly redis: Redis,
    @Inject(REDIS_KEYS) private readonly keys: RedisKeys,
  ) {}

  async save(c: Challenge, ttlMs: number): Promise<void> {
    const stored: StoredChallenge = {
      ID: c.id,
      AdminID: c.adminId,
      Attempts: c.attempts,
      EnrolSecret: c.enrolSecret,
    };
    await this.redis.set(this.keys.key('mfa', c.id), JSON.stringify(stored), 'PX', ttlMs);
  }

  async get(id: string): Promise<Challenge> {
    const raw = await this.redis.get(this.keys.key('mfa', id));
    if (raw === null) {
      throw new DomainError(IdentityReasons.ChallengeExpired);
    }
    let s: StoredChallenge;
    try {
      s = JSON.parse(raw) as StoredChallenge;
    } catch (cause) {
      throw new Error('decode challenge', { cause });
    }
    return { id: s.ID, adminId: s.AdminID, attempts: s.Attempts, enrolSecret: s.EnrolSecret };
  }

  async delete(id: string): Promise<void> {
    await this.redis.del(this.keys.key('mfa', id));
  }
}
