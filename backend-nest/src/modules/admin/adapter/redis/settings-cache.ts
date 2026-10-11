import { Inject, Injectable } from '@nestjs/common';
import { LOGGER, type Logger } from '../../../../platform/logging/logger';
import { Cache } from '../../../../platform/redis/cache';
import { REDIS_KEYS, type RedisKeys } from '../../../../platform/redis/redis-client';
import { type SettingsCache } from '../../port/settings-repository';

/** Bounds staleness if an invalidation is lost; edits delete the key at once. */
const SETTINGS_TTL_MS = 10 * 60_000;

/** Setting values in Redis under `cache:settings`. */
@Injectable()
export class RedisSettingsCache implements SettingsCache {
  private readonly key: string;

  constructor(
    @Inject(Cache) private readonly cache: Pick<Cache, 'get' | 'set' | 'delete'>,
    @Inject(REDIS_KEYS) keys: RedisKeys,
    @Inject(LOGGER) private readonly log: Logger,
  ) {
    this.key = keys.key('cache', 'settings');
  }

  read(): Promise<Record<string, string> | undefined> {
    return this.cache.get<Record<string, string>>(this.key).catch(() => undefined);
  }

  async write(values: Record<string, string>): Promise<void> {
    await this.cache.set(this.key, values, SETTINGS_TTL_MS).catch((err: unknown) => {
      this.log.warn({ err }, 'settings cache write failed');
    });
  }

  async invalidate(): Promise<void> {
    await this.cache.delete(this.key).catch((err: unknown) => {
      this.log.error({ err }, 'settings cache invalidation failed');
    });
  }
}
