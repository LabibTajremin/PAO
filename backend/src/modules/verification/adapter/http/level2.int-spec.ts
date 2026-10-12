import { v7 as uuid } from 'uuid';
import { startTestApi, type TestApi } from '../../../../../test/kit/api';
import { seedCatalog } from '../../../../../test/kit/catalog';
import { relayEvents } from '../../../../../test/kit/events';
import { adminSession } from '../../../../../test/kit/identity';
import { upload } from '../../../../../test/kit/media';
import { near, service, verifiedProvider } from '../../../../../test/kit/provider';
import { DATABASE, type Database } from '../../../../platform/db/database';
import { type JobScheduler } from '../../../../platform/jobs/scheduler';
import { PROVIDER_SERVICE, type ProviderService } from '../../../provider/contract';
import { VerificationWorker } from '../inproc/worker-hooks';

const electrician = service('electrician');
const DAY_MS = 24 * 60 * 60 * 1000;
const HOUR_MS = 60 * 60 * 1000;
const at = (d: number) => new Date(d).toISOString().replace(/\.\d{3}Z$/, 'Z');

describe('Level 2 sessions and expiry', () => {
  let api: TestApi;

  beforeEach(async () => {
    api = await startTestApi();
    await seedCatalog(api);
  });

  it('fails, cools off, then passes (TestLevel2_FailCoolOffPass)', async () => {
    const p = await verifiedProvider(api, '01712345678', 'male', electrician);
    let auth = { token: (await adminSession(api, ['verifier'])).accessToken };
    const now = () => api.clock.now().getTime();
    const body = {
      providerId: p.id,
      serviceId: electrician,
      scheduledAt: at(now() + 48 * HOUR_MS),
      location: 'PAO office, Gulshan 1',
    };
    const created = await api.do('POST', '/v1/admin/level2-sessions', body, auth);
    expect(created.status).toBe(201);
    const first = created.body?.id as string;
    const fail = {
      result: 'fail',
      checklist: [{ item: 'Safe wiring', passed: false }],
      notes: 'Unsafe joints',
      visitLocation: { lat: 23.79, lng: 90.41 },
      photoMediaIds: [await upload(api, p.id, 'admin', 'level2_photo')],
    };
    const result = `/v1/admin/level2-sessions/${first}/result`;
    expect(await api.do('POST', result, fail, auth)).toMatchObject({ body: { result: 'fail' } });
    expect((await api.do('POST', result, fail, auth)).code).toBe('SESSION_CLOSED');
    expect((await api.do('POST', '/v1/admin/level2-sessions', body, auth)).code).toBe(
      'LEVEL2_COOLING_OFF',
    );
    const cooling = await api.do('GET', '/v1/provider/verification', undefined, { token: p.token });
    expect(cooling.body).toMatchObject({ level2: { retryAfter: expect.any(String) as string } });
    api.clock.advance(15 * DAY_MS);
    auth = { token: (await adminSession(api, ['verifier'])).accessToken };
    const me = { token: await api.token(p.id, ['provider']) };
    body.scheduledAt = at(now() + HOUR_MS);
    const again = await api.do('POST', '/v1/admin/level2-sessions', body, auth);
    expect(again.status).toBe(201);
    const second = again.body?.id as string;
    const next = await api.do('GET', '/v1/provider/verification', undefined, me);
    expect(next.body).toMatchObject({ level2: { nextSession: { id: second } } });
    const pass = { result: 'pass', checklist: [{ item: 'Safe wiring', passed: true }] };
    const passed = await api.do('POST', `/v1/admin/level2-sessions/${second}/result`, pass, auth);
    expect(passed.status).toBe(200);
    await relayEvents(api);
    const level2 = await api.do('GET', '/v1/provider/verification', undefined, me);
    expect(level2.body).toMatchObject({ level: 2, badge: 'verified_pro' });
    const list = `/v1/admin/level2-sessions?limit=1&status=completed`;
    const page = await api.do('GET', `${list}&providerId=${p.id}`, undefined, auth);
    expect(page.body?.items).toHaveLength(1);
    const cursor = page.body?.nextCursor as string;
    const rest = await api.do('GET', `${list}&cursor=${cursor}`, undefined, auth);
    expect(rest.body?.items).toHaveLength(1);
    expect(rest.body?.nextCursor).toBeUndefined();
    const got = await api.do('GET', `/v1/admin/level2-sessions/${first}`, undefined, auth);
    expect(got.body).toMatchObject({ notes: 'Unsafe joints' });
    expect(
      (await api.do('GET', `/v1/admin/level2-sessions/${uuid()}`, undefined, auth)).status,
    ).toBe(404);
    expect(
      (await api.do('GET', '/v1/admin/level2-sessions?cursor=%25', undefined, auth)).status,
    ).toBe(422);
    const stranger = { ...body, providerId: uuid(), location: 'Office' };
    expect((await api.do('POST', '/v1/admin/level2-sessions', stranger, auth)).code).toBe(
      'LEVEL2_NOT_ELIGIBLE',
    );
    const unknown = { ...stranger, serviceId: uuid() };
    expect((await api.do('POST', '/v1/admin/level2-sessions', unknown, auth)).status).toBe(422);
  });

  it('reminds, then drops the level (TestExpiry_RemindsThenDropsLevel)', async () => {
    const p = await verifiedProvider(api, '01712345678', 'male', electrician);
    await api.do('POST', '/v1/provider/presence/online', near, { token: p.token });
    const jobs: Record<string, () => Promise<void>> = {};
    const scheduler = {
      dailyAt: (_h: number, _m: number, name: string, job: () => Promise<void>) =>
        (jobs[name] = job),
    };
    api.app.get(VerificationWorker).schedule(scheduler as unknown as JobScheduler);
    const db = api.app.get<Database>(DATABASE);
    const { rows } = await db.query<{ expires_at: Date }>(
      `SELECT expires_at FROM verification.items WHERE provider_id = $1 AND item_type = 'police_clearance'`,
      [p.id],
    );
    const expires = rows[0]?.expires_at.getTime() ?? 0;
    api.clock.set(new Date(expires - 29 * DAY_MS - 12 * HOUR_MS));
    await jobs['verification.expiry_reminders']?.();
    await jobs['verification.expiry_reminders']?.();
    const sent = await db.query<{ n: string }>(
      `SELECT count(*) AS n FROM verification.outbox WHERE event_name = 'verification.DocumentExpiring'`,
    );
    expect(sent.rows[0]?.n).toBe('1');
    api.clock.advance(31 * DAY_MS);
    await jobs['verification.expire_documents']?.();
    await relayEvents(api);
    const me = { token: await api.token(p.id, ['provider']) };
    const st = await api.do('GET', '/v1/provider/verification', undefined, me);
    expect(st.body).toMatchObject({ level: 0, canReceiveBookings: false });
    expect(await api.app.get<ProviderService>(PROVIDER_SERVICE).isAvailable(p.id)).toBe(false);
  });
});
