import { type Provider } from '@nestjs/common';
import { LOGGER, type Logger } from '../../../../platform/logging/logger';
import { Cache } from '../../../../platform/redis/cache';
import { REDIS_KEYS, type RedisKeys } from '../../../../platform/redis/redis-client';
import { type CachedValue } from '../../port/console';

/** One JSON value in Redis under `cache:{name}`; an outage is logged and reads as a miss. */
export class RedisCachedValue<T> implements CachedValue<T> {
  constructor(
    private readonly cache: Pick<Cache, 'get' | 'set' | 'delete'>,
    private readonly key: string,
    private readonly ttlMs: number,
    private readonly log: Logger,
  ) {}

  read(): Promise<T | undefined> {
    return this.cache.get<T>(this.key).catch(() => undefined);
  }

  async write(value: T): Promise<void> {
    await this.cache.set(this.key, value, this.ttlMs).catch((err: unknown) => {
      this.log.warn({ err, key: this.key }, 'cache write failed');
    });
  }

  async invalidate(): Promise<void> {
    await this.cache.delete(this.key).catch((err: unknown) => {
      this.log.error({ err, key: this.key }, 'cache invalidation failed');
    });
  }
}

/** Provides a {@link RedisCachedValue} under `token`. */
export function cachedValueProvider(token: symbol, name: string, ttlMs: number): Provider {
  return {
    provide: token,
    inject: [Cache, REDIS_KEYS, LOGGER],
    useFactory: (cache: Cache, keys: RedisKeys, log: Logger) =>
      new RedisCachedValue(cache, keys.key('cache', name), ttlMs, log),
  };
}
