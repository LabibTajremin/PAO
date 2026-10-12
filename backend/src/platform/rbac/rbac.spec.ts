import type Redis from 'ioredis';
import { RedisKeys } from '../redis/redis-client';
import { RbacChecker } from './rbac';

describe('RbacChecker', () => {
  it('still answers when the grant cache cannot be written', async () => {
    const failingMulti = {
      sadd: () => failingMulti,
      expire: () => failingMulti,
      exec: () => Promise.reject(new Error('redis down')),
    };
    const redis = {
      get: () => Promise.resolve(null),
      smembers: () => Promise.resolve([]),
      multi: () => failingMulti,
    } as unknown as Redis;
    const source = {
      loadGrants: () => Promise.resolve({ permissions: ['booking:create'], screens: ['C07'] }),
    };
    const rbac = new RbacChecker(redis, new RedisKeys('t'), source);
    expect(await rbac.has(['customer'], 'booking:create')).toBe(true);
  });
});
