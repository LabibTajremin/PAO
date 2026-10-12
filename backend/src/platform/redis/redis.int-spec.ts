import { Test } from '@nestjs/testing';
import type Redis from 'ioredis';
import { closedRedis, testRedis } from '../../../test/kit/redis';
import { testEnv } from '../../../test/kit/cleanup';
import { FakeClock } from '../clock/fake-clock';
import { type AppConfig } from '../config/app-config';
import { ConfigModule } from '../config/config.module';
import { UuidV7Generator } from '../ids/id-generator';
import { RuntimeModule } from '../runtime.module';
import { Cache } from './cache';
import { Denylist } from './denylist';
import { IdempotencyStore } from './idempotency-store';
import { Locker, LockHeldError } from './locker';
import { RateLimiter } from './rate-limiter';
import { connectRedis, REDIS, REDIS_KEYS, RedisKeys } from './redis-client';
import { RedisModule } from './redis.module';

const MINUTE = 60_000;
const ids = new UuidV7Generator();

describe('connectRedis', () => {
  it('rejects bad URLs and unreachable servers, and builds keys', async () => {
    await expect(connectRedis('nope://')).rejects.toThrow('parse redis url');
    await expect(connectRedis('redis://127.0.0.1:1/0')).rejects.toThrow('ping redis');
    expect(new RedisKeys('dev').key('otp', '+880')).toBe('pao:dev:otp:+880');
  });
});

describe('RateLimiter', () => {
  it('counts hits in a sliding window', async () => {
    const { redis, keys } = await testRedis();
    const clock = new FakeClock(new Date('2026-10-09T10:00:00Z'));
    const limiter = new RateLimiter(redis, clock, ids);
    const key = keys.key('rl', 'otp', 'phone');
    for (let i = 0; i < 3; i++) {
      expect((await limiter.allow(key, 3, 15 * MINUTE)).allowed).toBe(true);
      clock.advance(MINUTE);
    }
    expect(await limiter.allow(key, 3, 15 * MINUTE)).toEqual({
      allowed: false,
      retryAfterMs: 12 * MINUTE,
    });
    clock.advance(12 * MINUTE);
    expect((await limiter.allow(key, 3, 15 * MINUTE)).allowed).toBe(true);
  });

  it('waits at least a second and reports a dead connection', async () => {
    const { redis, keys } = await testRedis();
    const clock = new FakeClock(new Date('2026-10-09T10:00:00Z'));
    const limiter = new RateLimiter(redis, clock, ids);
    await limiter.allow(keys.key('rl', 'x'), 1, 500);
    expect((await limiter.allow(keys.key('rl', 'x'), 1, 500)).retryAfterMs).toBe(1000);
    const closed = new RateLimiter(await closedRedis(), clock, ids);
    await expect(closed.allow(keys.key('rl', 'x'), 1, 1000)).rejects.toThrow('rate limit');
  });
});

describe('Locker', () => {
  it('lets only one holder in and never releases a newer holder', async () => {
    const { redis, keys } = await testRedis();
    const locker = new Locker(redis, ids);
    const key = keys.key('lock', 'booking', 'b1');
    const release = await locker.acquire(key, 10_000);
    await expect(locker.acquire(key, 10_000)).rejects.toBeInstanceOf(LockHeldError);
    await release();
    await locker.acquire(key, 10_000);
    await release();
    expect(await redis.exists(key)).toBe(1);
    await expect(new Locker(await closedRedis(), ids).acquire(key, 1000)).rejects.toThrow(
      'acquire lock',
    );
  });

  it('reports a failed release', async () => {
    const { keys } = await testRedis();
    const own = await connectRedis(testEnv('PAO_TEST_REDIS_URL'));
    const release = await new Locker(own, ids).acquire(keys.key('lock', 'x'), 1000);
    await own.quit();
    await expect(release()).rejects.toThrow('release lock');
  });
});

describe('IdempotencyStore', () => {
  it('replays the first answer and frees released keys', async () => {
    const { redis, keys } = await testRedis();
    const store = new IdempotencyStore(redis);
    const key = keys.key('idem', 'u1', 'k1');
    expect(await store.reserve(key, 'h1')).toEqual({
      reserved: true,
      record: { requestHash: 'h1', done: false },
    });
    const inFlight = await store.reserve(key, 'h1');
    expect(inFlight.reserved || inFlight.record.done).toBe(false);
    await store.complete(key, { requestHash: 'h1', status: 201, body: Buffer.from('{}') });
    expect(JSON.parse((await redis.get(key)) ?? '')).toEqual({
      h: 'h1',
      d: true,
      s: 201,
      b: 'e30=',
    });
    const replay = await store.reserve(key, 'h1');
    expect(replay.reserved).toBe(false);
    expect(replay.record).toMatchObject({ done: true, status: 201 });
    expect(replay.record.body?.toString()).toBe('{}');
    await store.release(key);
    expect((await store.reserve(key, 'h2')).reserved).toBe(true);
    await store.complete(key, { requestHash: 'h2', body: Buffer.alloc(0) });
    expect(JSON.parse((await redis.get(key)) ?? '')).toEqual({ h: 'h2', d: true });
    expect(await redis.pttl(key)).toBeGreaterThan(23 * 60 * MINUTE);
  });

  it('reports garbage and dead connections', async () => {
    const { redis, keys } = await testRedis();
    const key = keys.key('idem', 'u1', 'k2');
    await redis.set(key, 'garbage');
    await expect(new IdempotencyStore(redis).reserve(key, 'h1')).rejects.toThrow('decode');
    const closed = new IdempotencyStore(await closedRedis());
    await expect(closed.reserve(key, 'h')).rejects.toThrow('reserve');
    await expect(closed.complete(key, { requestHash: 'h' })).rejects.toThrow('complete');
    await expect(closed.release(key)).rejects.toThrow('release');
  });
});

describe('Denylist', () => {
  it('revokes token ids until they expire', async () => {
    const { redis, keys } = await testRedis();
    const denylist = new Denylist(redis, keys);
    await denylist.deny('j1', MINUTE);
    await denylist.deny('j2', 0);
    expect(await denylist.isDenied('j1')).toBe(true);
    expect(await denylist.isDenied('j2')).toBe(false);
    expect(await redis.exists(keys.key('deny', 'jti', 'j1'))).toBe(1);
    const closed = new Denylist(await closedRedis(), keys);
    await expect(closed.deny('j', MINUTE)).rejects.toThrow('deny token');
    await expect(closed.isDenied('j')).rejects.toThrow('check denylist');
  });
});

describe('Cache', () => {
  it('stores JSON values for a while', async () => {
    const { redis, keys } = await testRedis();
    const cache = new Cache(redis);
    const key = keys.key('cache', 'x');
    expect(await cache.get(key)).toBeUndefined();
    await cache.set(key, { v: 1 }, MINUTE);
    expect(await cache.get<{ v: number }>(key)).toEqual({ v: 1 });
    await cache.delete(key);
    expect(await cache.get(key)).toBeUndefined();
    await expect(new Cache(await closedRedis()).get(key)).rejects.toThrow();
  });
});

describe('RedisModule', () => {
  it('connects, names keys after APP_ENV and disconnects on shutdown', async () => {
    const config = { appEnv: 'staging', redisUrl: testEnv('PAO_TEST_REDIS_URL') } as AppConfig;
    const ref = await Test.createTestingModule({
      imports: [ConfigModule.forRoot(config), RuntimeModule, RedisModule],
    }).compile();
    const app = await ref.createNestApplication().init();
    expect(app.get<RedisKeys>(REDIS_KEYS).key('x')).toBe('pao:staging:x');
    expect(app.get(RateLimiter)).toBeInstanceOf(RateLimiter);
    const redis = app.get<Redis>(REDIS);
    const ended = new Promise((resolve) => redis.once('end', resolve));
    await app.close();
    await ended;
    expect(redis.status).toBe('end');
  });

  it('shuts down when the connection is already gone', async () => {
    const config = { appEnv: 'dev', redisUrl: testEnv('PAO_TEST_REDIS_URL') } as AppConfig;
    const ref = await Test.createTestingModule({
      imports: [ConfigModule.forRoot(config), RuntimeModule, RedisModule],
    }).compile();
    const app = await ref.createNestApplication().init();
    await app.get<Redis>(REDIS).quit();
    await expect(app.close()).resolves.toBeUndefined();
  });
});
