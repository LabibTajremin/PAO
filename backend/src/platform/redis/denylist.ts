import { Inject, Injectable } from '@nestjs/common';
import type Redis from 'ioredis';
import { REDIS, REDIS_KEYS, type RedisKeys } from './redis-client';

/**
 * Revoked access-token ids (logout, ban, role change), kept until the token would have
 * expired anyway: `deny:jti:{jti}`.
 */
@Injectable()
export class Denylist {
  constructor(
    @Inject(REDIS) private readonly redis: Redis,
    @Inject(REDIS_KEYS) private readonly keys: RedisKeys,
  ) {}

  /** Revokes `jti` for `ttlMs`, the token's remaining lifetime; nothing to do once expired. */
  async deny(jti: string, ttlMs: number): Promise<void> {
    if (ttlMs <= 0) {
      return;
    }
    try {
      await this.redis.set(this.keys.key('deny', 'jti', jti), '1', 'PX', ttlMs);
    } catch (cause) {
      throw new Error('deny token', { cause });
    }
  }

  /** Reports whether `jti` was revoked. */
  async isDenied(jti: string): Promise<boolean> {
    try {
      return (await this.redis.exists(this.keys.key('deny', 'jti', jti))) === 1;
    } catch (cause) {
      throw new Error('check denylist', { cause });
    }
  }
}
