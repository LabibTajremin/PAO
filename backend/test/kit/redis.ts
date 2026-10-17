// Redis isolation for specs: a private key prefix per call, removed afterwards. Other
// agents share the server, so nothing is ever flushed.
import { randomUUID } from 'node:crypto';
import Redis from 'ioredis';
import { connectRedis, RedisKeys } from '../../src/platform/redis/redis-client';
import { onCleanup, testEnv } from './cleanup';

/** A connected client and a key builder whose prefix no other spec uses. */
export async function testRedis(): Promise<{ redis: Redis; keys: RedisKeys; env: string }> {
  const redis = await connectRedis(testEnv('PAO_TEST_REDIS_URL'));
  const env = 'test-' + randomUUID();
  const keys = new RedisKeys(env);
  onCleanup(async () => {
    const stale = await redis.keys(keys.key('*'));
    if (stale.length > 0) {
      await redis.del(...stale);
    }
    redis.disconnect();
  });
  return { redis, keys, env };
}

/** A client whose connection is already closed, to exercise error paths. */
export async function closedRedis(): Promise<Redis> {
  const redis = new Redis(testEnv('PAO_TEST_REDIS_URL'), {
    lazyConnect: true,
    maxRetriesPerRequest: 0,
  });
  redis.on('error', () => undefined);
  await redis.connect();
  await redis.quit();
  return redis;
}
