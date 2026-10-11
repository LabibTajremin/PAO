import { randomUUID } from 'node:crypto';
import { closedRedis, testRedis } from '../../../../../test/kit/redis';
import { FakeClock } from '../../../../platform/clock/fake-clock';
import { UuidV7Generator } from '../../../../platform/ids/id-generator';
import { RateLimiter } from '../../../../platform/redis/rate-limiter';
import { RESEND_AFTER_MS } from '../../domain/code';
import {
  RedisChallengeStore,
  RedisCodeStore,
  RedisSendThrottle,
  RedisSessionStore,
} from './redis-stores';

const PHONE = '+8801712345678';

describe('identity Redis stores', () => {
  it('report a closed connection', async () => {
    const closed = await closedRedis();
    const { keys } = await testRedis();
    await expect(new RedisCodeStore(closed, keys).get('login', PHONE)).rejects.toThrow();
    await expect(new RedisSessionStore(closed, keys).get(randomUUID())).rejects.toThrow();
    await expect(
      new RedisSessionStore(closed, keys).listForAccount(randomUUID()),
    ).rejects.toThrow();
    await expect(new RedisChallengeStore(closed, keys).get('x')).rejects.toThrow();
  });

  it('keep codes per purpose and phone', async () => {
    const { redis, keys } = await testRedis();
    const codes = new RedisCodeStore(redis, keys);
    await codes.save('login', PHONE, { hash: 'h', attempts: 0 });
    await codes.incrementAttempts('login', PHONE);
    expect(await codes.get('login', PHONE)).toEqual({ hash: 'h', attempts: 1 });
    await expect(codes.get('delete_account', PHONE)).rejects.toThrow('code_expired');
    await codes.delete('login', PHONE);
    await expect(codes.get('login', PHONE)).rejects.toThrow('code_expired');
  });

  it('drop index entries of expired families and report broken ones', async () => {
    const { redis, keys } = await testRedis();
    const sessions = new RedisSessionStore(redis, keys);
    const accountId = randomUUID();
    const live = {
      id: randomUUID(),
      accountId,
      app: 'customer',
      currentHash: 'h',
      accessTokenId: 'j',
      accessExpiresAt: new Date(1_800_000_000_000),
    };
    await sessions.save(live, 60_000);
    await redis.sadd(keys.key('sess', accountId), randomUUID());
    expect(await sessions.listForAccount(accountId)).toEqual([live]);
    expect(await redis.scard(keys.key('sess', accountId))).toBe(1);
    await sessions.delete(live);
    expect(await sessions.listForAccount(accountId)).toEqual([]);
    const broken = randomUUID();
    await redis.sadd(keys.key('sess', accountId), broken);
    await redis.set(keys.key('rt', broken), 'not-a-hash');
    await expect(sessions.listForAccount(accountId)).rejects.toThrow('WRONGTYPE');
  });

  it('round-trip challenges and refuse garbage', async () => {
    const { redis, keys } = await testRedis();
    const challenges = new RedisChallengeStore(redis, keys);
    const c = { id: 'c1', adminId: randomUUID(), attempts: 2, enrolSecret: 'S' };
    await challenges.save(c, 60_000);
    expect(await challenges.get('c1')).toEqual(c);
    expect(JSON.parse((await redis.get(keys.key('mfa', 'c1')))!)).toMatchObject({
      AdminID: c.adminId,
    });
    await challenges.delete('c1');
    await expect(challenges.get('c1')).rejects.toThrow('challenge_expired');
    await redis.set(keys.key('mfa', 'x'), '{');
    await expect(challenges.get('x')).rejects.toThrow('decode challenge');
  });

  it('throttle sends, skipping the IP window for server-side sends', async () => {
    const { redis, keys } = await testRedis();
    const clock = new FakeClock(new Date());
    const throttle = new RedisSendThrottle(
      new RateLimiter(redis, clock, new UuidV7Generator()),
      keys,
    );
    expect(await throttle.retryAfterMs(PHONE, '9.9.9.9')).toBe(0);
    expect(await throttle.retryAfterMs(PHONE, '9.9.9.9')).toBe(RESEND_AFTER_MS);
    for (let i = 0; i < 10; i++) {
      await redis.zadd(keys.key('rl', 'otp', 'ip', '8.8.8.8'), clock.now().getTime(), `x${i}`);
    }
    const other = '+8801812345678';
    expect(await throttle.retryAfterMs(other, '8.8.8.8')).toBeGreaterThan(0);
    clock.advance(RESEND_AFTER_MS);
    expect(await throttle.retryAfterMs(other, undefined)).toBe(0);
    clock.advance(RESEND_AFTER_MS);
    expect(await throttle.retryAfterMs(PHONE, '')).toBe(0);
    clock.advance(RESEND_AFTER_MS);
    expect(await throttle.retryAfterMs(PHONE, undefined)).toBe(0);
    clock.advance(RESEND_AFTER_MS);
    // A fourth send to one phone within 15 minutes waits for the per-phone window.
    expect(await throttle.retryAfterMs(PHONE, undefined)).toBeGreaterThan(RESEND_AFTER_MS);
  });
});
