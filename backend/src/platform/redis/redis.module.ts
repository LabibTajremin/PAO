import { Global, Inject, Module, type OnApplicationShutdown } from '@nestjs/common';
import type Redis from 'ioredis';
import { APP_CONFIG, type AppConfig } from '../config/app-config';
import { Cache } from './cache';
import { Denylist } from './denylist';
import { IdempotencyStore } from './idempotency-store';
import { Locker } from './locker';
import { RateLimiter } from './rate-limiter';
import { connectRedis, REDIS, REDIS_KEYS, RedisKeys } from './redis-client';

const services = [RateLimiter, Locker, IdempotencyStore, Cache, Denylist];

/** Connects Redis at start-up and provides the coordination primitives built on it. */
@Global()
@Module({
  providers: [
    {
      provide: REDIS,
      inject: [APP_CONFIG],
      useFactory: (config: AppConfig) => connectRedis(config.redisUrl),
    },
    {
      provide: REDIS_KEYS,
      inject: [APP_CONFIG],
      useFactory: (config: AppConfig) => new RedisKeys(config.appEnv),
    },
    ...services,
  ],
  exports: [REDIS, REDIS_KEYS, ...services],
})
export class RedisModule implements OnApplicationShutdown {
  constructor(@Inject(REDIS) private readonly redis: Redis) {}

  async onApplicationShutdown(): Promise<void> {
    await this.redis.quit().catch(() => {
      this.redis.disconnect();
    });
  }
}
