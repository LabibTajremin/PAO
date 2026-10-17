import { Inject, Injectable } from '@nestjs/common';
import type Redis from 'ioredis';
import { ID_GENERATOR, type IdGenerator } from '../ids/id-generator';
import { REDIS } from './redis-client';

// Deletes the lock only while it still holds our token, so a holder whose lock expired
// cannot release someone else's.
const RELEASE_IF_OWNER = `
if redis.call('GET', KEYS[1]) == ARGV[1] then
  return redis.call('DEL', KEYS[1])
end
return 0
`;

/** Thrown when another holder owns the lock. */
export class LockHeldError extends Error {
  constructor(key: string) {
    super(`lock held by another holder: ${key}`);
    this.name = 'LockHeldError';
  }
}

/** Releases a lock; safe to call after the lock expired. */
export type ReleaseLock = () => Promise<void>;

/** Hands out short-lived distributed locks (`SET NX PX`), e.g. `lock:booking:{id}`. */
@Injectable()
export class Locker {
  constructor(
    @Inject(REDIS) private readonly redis: Redis,
    @Inject(ID_GENERATOR) private readonly ids: IdGenerator,
  ) {}

  /** Takes the lock for `ttlMs` or throws {@link LockHeldError}. */
  async acquire(key: string, ttlMs: number): Promise<ReleaseLock> {
    const token = this.ids.newId();
    let ok: string | null;
    try {
      ok = await this.redis.set(key, token, 'PX', ttlMs, 'NX');
    } catch (cause) {
      throw new Error(`acquire lock ${key}`, { cause });
    }
    if (ok === null) {
      throw new LockHeldError(key);
    }
    return async () => {
      try {
        await this.redis.eval(RELEASE_IF_OWNER, 1, key, token);
      } catch (cause) {
        throw new Error(`release lock ${key}`, { cause });
      }
    };
  }
}
