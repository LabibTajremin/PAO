import { Inject, Injectable } from '@nestjs/common';
import type Redis from 'ioredis';
import { REDIS } from './redis-client';

/** Stores rebuildable values (rendered catalog trees, settings, dashboards) as JSON. */
@Injectable()
export class Cache {
  constructor(@Inject(REDIS) private readonly redis: Redis) {}

  /** Returns the cached value, or undefined when absent. */
  async get<T>(key: string): Promise<T | undefined> {
    const raw = await this.redis.get(key);
    return raw === null ? undefined : (JSON.parse(raw) as T);
  }

  /** Stores `value` for `ttlMs`. */
  async set(key: string, value: unknown, ttlMs: number): Promise<void> {
    await this.redis.set(key, JSON.stringify(value), 'PX', ttlMs);
  }

  /** Forgets a value. */
  async delete(key: string): Promise<void> {
    await this.redis.del(key);
  }
}
