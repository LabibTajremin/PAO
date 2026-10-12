import type Redis from 'ioredis';
import { v7 as uuid } from 'uuid';
import { startTestApi, type TestApi } from '../../../../../test/kit/api';
import { seedCatalog } from '../../../../../test/kit/catalog';
import { enrol, near, online, service } from '../../../../../test/kit/provider';
import { DATABASE, type Database } from '../../../../platform/db/database';
import { type JobScheduler } from '../../../../platform/jobs/scheduler';
import { REDIS } from '../../../../platform/redis/redis-client';
import { PROVIDER_SERVICE, type ProviderService } from '../../contract';
import { ProviderWorker } from '../inproc/worker-hooks';

const PHONE = '01712345678';
const electrician = service('electrician');
const homeSalon = service('home-salon');

describe('provider presence', () => {
  let api: TestApi;
  let providers: ProviderService;

  beforeEach(async () => {
    api = await startTestApi();
    await seedCatalog(api);
    providers = api.app.get(PROVIDER_SERVICE);
  });

  it('goes online, beats and goes offline (TestPresence_OnlineHeartbeatOffline)', async () => {
    const unverified = await enrol(api, '01912345678', 'male', electrician);
    const refused = await api.do('POST', '/v1/provider/presence/online', near, {
      token: unverified.token,
    });
    expect(refused.code).toBe('NOT_VERIFIED');
    const { id, token } = await online(
      api,
      { phone: PHONE, gender: 'male', level: 1 },
      electrician,
    );
    const beat = '/v1/provider/presence/heartbeat';
    expect((await api.do('POST', beat, near, { token })).status).toBe(200);
    const profile = await api.do('GET', '/v1/provider/profile', undefined, { token });
    expect(profile.body).toMatchObject({ online: true, badge: 'verified' });
    expect(await providers.isAvailable(id)).toBe(true);
    const off = await api.do('POST', '/v1/provider/presence/offline', undefined, { token });
    expect(off.body?.online).toBe(false);
    expect((await api.do('POST', beat, near, { token })).code).toBe('OFFLINE');
    await api.do('POST', '/v1/provider/presence/online', near, { token });
    await api.app.get<Redis>(REDIS).del(api.keys.key('presence', 'hb', id));
    const jobs: Record<string, () => Promise<void>> = {};
    const scheduler = {
      every: (_ms: number, name: string, job: () => Promise<void>) => (jobs[name] = job),
    };
    api.app.get(ProviderWorker).schedule(scheduler as unknown as JobScheduler);
    await jobs['provider.reap_lost_presence']?.();
    expect(await providers.isAvailable(id)).toBe(false);
    await api.do('POST', '/v1/provider/presence/online', near, { token });
    await providers.forceOffline(id);
    expect((await api.do('POST', beat, near, { token })).code).toBe('OFFLINE');
    await api.do('POST', '/v1/provider/presence/online', near, { token });
    const services = { serviceIds: [electrician], experienceYears: 9 };
    await api.do('PUT', '/v1/provider/enrolment/services', services, { token });
    expect(await providers.isAvailable(id)).toBe(false);
    const stranger = await api.token(uuid(), ['provider']);
    for (const path of ['/v1/provider/presence/online', beat]) {
      expect((await api.do('POST', path, near, { token: stranger })).status).toBe(404);
    }
    // Go answered 404 here too, which the spec does not list for this operation.
    const offline = await api.do('POST', '/v1/provider/presence/offline', undefined, {
      token: stranger,
      unchecked: true,
    });
    expect(offline.status).toBe(404);
  });

  it('ranks and honours women-only (TestFindNearby_RanksAndHonoursWomenOnly)', async () => {
    const man = await online(
      api,
      { phone: '01712345601', gender: 'male', level: 1 },
      electrician,
      homeSalon,
    );
    const woman = await online(
      api,
      { phone: '01712345602', gender: 'female', level: 1 },
      homeSalon,
    );
    const pro = await online(
      api,
      { phone: '01712345603', gender: 'female', level: 2 },
      electrician,
      homeSalon,
    );
    const dhaka = { lat: 23.7937, lng: 90.4066 };
    const q = { point: dhaka, radiusM: 5000, womenProvidersOnly: false, limit: 10 } as const;
    const salon = await providers.findNearby({ ...q, serviceId: homeSalon, sort: 'distance' });
    expect(salon.map((c) => c.providerId)).toEqual([pro.id, woman.id]);
    expect(salon[0]?.name).toBe('Rahim Uddin');
    const elec = await providers.findNearby({
      ...q,
      serviceId: electrician,
      sort: 'rating',
      limit: 0,
    });
    expect(elec.map((c) => c.providerId)).toEqual([pro.id, man.id]);
    await api.app
      .get<Database>(DATABASE)
      .query('UPDATE catalog.services SET requires_level_2 = true WHERE id = $1', [homeSalon]);
    const level2 = await providers.findNearby({ ...q, serviceId: homeSalon, sort: 'distance' });
    expect(level2.map((c) => c.providerId)).toEqual([pro.id]);
    const far = {
      ...q,
      point: { lat: 22.35, lng: 91.78 },
      serviceId: electrician,
      sort: 'distance',
    } as const;
    expect(await providers.findNearby(far)).toEqual([]);
    await expect(
      providers.findNearby({ ...q, serviceId: uuid(), sort: 'distance' }),
    ).rejects.toThrow();
  });
});
