import { Test } from '@nestjs/testing';
import { discardLogger, LOGGER } from '../../../../platform/logging/logger';
import { Cache } from '../../../../platform/redis/cache';
import { REDIS_KEYS, RedisKeys } from '../../../../platform/redis/redis-client';
import { type CachedValue } from '../../port/console';
import { cachedValueProvider, RedisCachedValue } from './cached-value';

const boom = new Error('boom');

function store(down: boolean) {
  const data = new Map<string, unknown>();
  const fail = () => Promise.reject(boom);
  return {
    data,
    cache: {
      get: down ? fail : <T>(k: string) => Promise.resolve(data.get(k) as T | undefined),
      set: down ? fail : (k: string, v: unknown) => Promise.resolve(void data.set(k, v)),
      delete: down ? fail : (k: string) => Promise.resolve(void data.delete(k)),
    },
  };
}

describe('RedisCachedValue', () => {
  it('keeps one JSON value', async () => {
    const { data, cache } = store(false);
    const v = new RedisCachedValue<{ a: string }>(cache, 'k', 1000, discardLogger());
    expect(await v.read()).toBeUndefined();
    await v.write({ a: '1' });
    expect(await v.read()).toEqual({ a: '1' });
    await v.invalidate();
    expect(data.size).toBe(0);
  });

  it('treats an outage as a miss', async () => {
    const v = new RedisCachedValue(store(true).cache, 'k', 1000, discardLogger());
    expect(await v.read()).toBeUndefined();
    await expect(v.write({})).resolves.toBeUndefined();
    await expect(v.invalidate()).resolves.toBeUndefined();
  });

  it('is provided under cache:{name}', async () => {
    const { data, cache } = store(false);
    const token = Symbol('value');
    const ref = await Test.createTestingModule({
      providers: [
        { provide: Cache, useValue: cache },
        { provide: REDIS_KEYS, useValue: new RedisKeys('test') },
        { provide: LOGGER, useValue: discardLogger() },
        cachedValueProvider(token, 'settings', 1000),
      ],
    }).compile();
    await ref.get<CachedValue<number>>(token).write(1);
    expect(data.get('pao:test:cache:settings')).toBe(1);
  });
});
