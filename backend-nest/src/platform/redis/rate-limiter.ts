import { Inject, Injectable } from '@nestjs/common';
import type Redis from 'ioredis';
import { CLOCK, type Clock } from '../clock/clock';
import { ID_GENERATOR, type IdGenerator } from '../ids/id-generator';
import { REDIS } from './redis-client';

// Drops hits older than the window, then records this hit if the limit allows it, in
// one atomic step. Returns {allowed, oldest hit in ms}.
const SLIDING_WINDOW = `
local key, now, window, limit, member = KEYS[1], tonumber(ARGV[1]), tonumber(ARGV[2]), tonumber(ARGV[3]), ARGV[4]
redis.call('ZREMRANGEBYSCORE', key, '-inf', now - window)
if redis.call('ZCARD', key) < limit then
  redis.call('ZADD', key, now, member)
  redis.call('PEXPIRE', key, window)
  return {1, 0}
end
local oldest = redis.call('ZRANGE', key, 0, 0, 'WITHSCORES')
return {0, tonumber(oldest[2])}
`;

/** The outcome of a rate-limit check. */
export interface RateDecision {
  readonly allowed: boolean;
  /** How long until the oldest counted hit leaves the window; at least one second. */
  readonly retryAfterMs: number;
}

/** A sliding-window limiter: at most `limit` hits per window per key. */
@Injectable()
export class RateLimiter {
  constructor(
    @Inject(REDIS) private readonly redis: Redis,
    @Inject(CLOCK) private readonly clock: Clock,
    @Inject(ID_GENERATOR) private readonly ids: IdGenerator,
  ) {}

  /** Records a hit on `key` if fewer than `limit` hits happened within `windowMs`. */
  async allow(key: string, limit: number, windowMs: number): Promise<RateDecision> {
    const now = this.clock.now().getTime();
    let result: [number, number];
    try {
      result = (await this.redis.eval(
        SLIDING_WINDOW,
        1,
        key,
        now,
        windowMs,
        limit,
        `${now}-${this.ids.newId()}`,
      )) as [number, number];
    } catch (cause) {
      throw new Error(`rate limit ${key}`, { cause });
    }
    if (result[0] === 1) {
      return { allowed: true, retryAfterMs: 0 };
    }
    return { allowed: false, retryAfterMs: Math.max(result[1] + windowMs - now, 1000) };
  }
}
