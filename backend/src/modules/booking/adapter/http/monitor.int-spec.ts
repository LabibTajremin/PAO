import { v7 as uuid } from 'uuid';
import { startTestApi, type TestApi } from '../../../../../test/kit/api';
import { completedJob, type Job, requestedJob } from '../../../../../test/kit/booking';
import { adminSession } from '../../../../../test/kit/identity';
import { service } from '../../../../../test/kit/provider';
import { DATABASE, type Database } from '../../../../platform/db/database';
import { addDays, dhakaDay, isoDate } from '../../domain/earnings';

describe('admin bookings monitor (TestMonitor_FiltersAndDetail)', () => {
  let api: TestApi;
  let done: Job;
  let open: Job;
  let auth: { token: string };

  beforeAll(async () => {
    api = await startTestApi();
    done = await completedJob(api, '01712345691', '01812345691');
    open = await requestedJob(api, '01712345692', '01812345692');
    auth = { token: (await adminSession(api, ['support_agent'])).accessToken };
  });

  const count = async (query: string) => {
    const r = await api.do('GET', `/v1/admin/bookings${query}`, undefined, auth);
    expect(r.status).toBe(200);
    return (r.body?.items as unknown[]).length;
  };

  it('filters by status, service, area and Dhaka dates', async () => {
    const today = dhakaDay(api.clock.now());
    const [day, tomorrow, yesterday] = [today, addDays(today, 1), addDays(today, -1)].map(isoDate);
    const cases: [string, number][] = [
      ['', 2],
      ['?status=completed', 1],
      [`?serviceId=${service('electrician')}`, 2],
      [`?serviceId=${uuid()}`, 0],
      ['?area=banani', 2],
      ['?area=Gulshan', 0],
      [`?from=${day}&to=${day}`, 2],
      [`?from=${tomorrow}`, 0],
      [`?to=${yesterday}`, 0],
    ];
    for (const [query, want] of cases) {
      expect(`${query} ${String(await count(query))}`).toBe(`${query} ${String(want)}`);
    }
  });

  it('pages newest first and shows both parties', async () => {
    const first = await api.do('GET', '/v1/admin/bookings?limit=1', undefined, auth);
    const [row] = first.body?.items as { id: string; counterpartName: string }[];
    expect(row?.id).toBe(open.id);
    expect(row?.counterpartName).toContain(' → ');
    const cursor = first.body?.nextCursor as string;
    const rest = await api.do(
      'GET',
      `/v1/admin/bookings?limit=1&cursor=${cursor}`,
      undefined,
      auth,
    );
    expect(rest.body?.items).toEqual([expect.objectContaining({ id: done.id })]);
    expect(rest.body?.nextCursor).toBeUndefined();
    const d = (await api.do('GET', `/v1/admin/bookings/${open.id}`, undefined, auth)).body;
    expect(d).toMatchObject({
      customer: { phone: expect.any(String) as unknown },
      provider: { phone: expect.any(String) as unknown },
    });
    expect((d?.timeline as unknown[]).length).toBeGreaterThan(0);
    expect((await api.do('GET', `/v1/admin/bookings/${uuid()}`, undefined, auth)).status).toBe(404);
    expect((await api.do('GET', '/v1/admin/bookings?cursor=%25', undefined, auth)).status).toBe(
      422,
    );
  });

  it('answers 500 once the database is gone', async () => {
    await api.app.get<Database>(DATABASE).close();
    for (const path of ['/v1/admin/bookings', `/v1/admin/bookings/${open.id}`]) {
      expect((await api.do('GET', path, undefined, auth)).status).toBe(500);
    }
  });
});
