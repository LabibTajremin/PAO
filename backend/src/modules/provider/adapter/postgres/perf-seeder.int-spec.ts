import { v4 as uuidv4 } from 'uuid';
import { startTestApi, type TestApi } from '../../../../../test/kit/api';
import { seedCatalog } from '../../../../../test/kit/catalog';
import { PERF_SEEDER, type PerfSeeder } from '../../../../platform/seeding/seeders';

describe('perf seeder (TestSeedPerf)', () => {
  let api: TestApi;

  beforeEach(async () => {
    api = await startTestApi();
    await seedCatalog(api);
  });

  it('puts a verified electrician online where customers find them', async () => {
    const seeder = api.app.get<PerfSeeder>(PERF_SEEDER, { strict: false });
    const id = uuidv4();
    await seeder.addOnlineProvider(id, { lat: 23.7937, lng: 90.4066 });
    const customer = await api.token(uuidv4(), ['customer']);
    const query =
      `serviceId=${seeder.serviceId}&subServiceId=${seeder.subServiceId}` +
      '&quantity=1&lat=23.7937&lng=90.4066';
    const r = await api.do('GET', `/v1/customer/providers/nearby?${query}`, undefined, {
      token: customer,
    });
    expect(r.status).toBe(200);
    expect(JSON.stringify(r.body)).toContain(id);
  });
});
