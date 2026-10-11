import { discardLogger } from '../../../../platform/logging/logger';
import { RedisKeys } from '../../../../platform/redis/redis-client';
import { RedisSettingsCache } from './settings-cache';

const boom = new Error('boom');

function cacheWith(down: boolean) {
  const data = new Map<string, unknown>();
  const fail = () => Promise.reject(boom);
  const store = {
    get: down ? fail : <T>(k: string) => Promise.resolve(data.get(k) as T | undefined),
    set: down ? fail : (k: string, v: unknown) => Promise.resolve(void data.set(k, v)),
    delete: down ? fail : (k: string) => Promise.resolve(void data.delete(k)),
  };
  return { data, cache: new RedisSettingsCache(store, new RedisKeys('test'), discardLogger()) };
}

describe('RedisSettingsCache', () => {
  it('stores values under cache:settings', async () => {
    const { data, cache } = cacheWith(false);
    expect(await cache.read()).toBeUndefined();
    await cache.write({ a: '1' });
    expect(data.get('pao:test:cache:settings')).toEqual({ a: '1' });
    expect(await cache.read()).toEqual({ a: '1' });
    await cache.invalidate();
    expect(data.size).toBe(0);
  });

  it('treats an outage as a miss', async () => {
    const { cache } = cacheWith(true);
    expect(await cache.read()).toBeUndefined();
    await expect(cache.write({ a: '1' })).resolves.toBeUndefined();
    await expect(cache.invalidate()).resolves.toBeUndefined();
  });
});
