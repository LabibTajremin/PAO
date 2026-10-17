// PRD §11: a provider's location is kept only while they are online. It lives only in
// Redis GEO sets (no table stores it), so going offline must leave no position behind.
import type Redis from 'ioredis';
import { startTestApi, type TestApi } from '../../test/kit/api';
import { seedCatalog } from '../../test/kit/catalog';
import { near, online, service } from '../../test/kit/provider';
import { REDIS } from '../platform/redis/redis-client';

describe('provider location', () => {
  let api: TestApi;
  let redis: Redis;

  beforeAll(async () => {
    api = await startTestApi();
    await seedCatalog(api);
    redis = api.app.get<Redis>(REDIS);
  });

  /** Every stored position of the provider, across all service GEO sets. */
  async function positions(id: string): Promise<unknown[]> {
    const sets = await redis.keys(api.keys.key('presence', 'svc', '*'));
    const found = await Promise.all(sets.map((k) => redis.geopos(k, id)));
    return found.flat().filter((p) => p !== null);
  }

  it('is stored while online and gone once the provider goes offline', async () => {
    const electrician = service('electrician');
    const p = await online(api, { phone: '01712345661', gender: 'male', level: 1 }, electrician);
    expect(await positions(p.id)).toHaveLength(1);
    const off = await api.do('POST', '/v1/provider/presence/offline', undefined, {
      token: p.token,
    });
    expect(off.body?.online).toBe(false);
    expect(await positions(p.id)).toEqual([]);
    const beat = await api.do('POST', '/v1/provider/presence/heartbeat', near, { token: p.token });
    expect(beat.code).toBe('OFFLINE');
    expect(await positions(p.id)).toEqual([]);
  });
});
