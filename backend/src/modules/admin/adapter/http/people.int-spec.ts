import { v7 as uuid } from 'uuid';
import { startTestApi, type TestApi } from '../../../../../test/kit/api';
import { completedJob, customer, type Job } from '../../../../../test/kit/booking';
import { envelope, relayEvents, subscribedBus } from '../../../../../test/kit/events';
import { adminSession, type AdminSession } from '../../../../../test/kit/identity';
import { enrolledProvider, service } from '../../../../../test/kit/provider';
import { DATABASE, type Database } from '../../../../platform/db/database';

type Json = Record<string, unknown>;

async function items(api: TestApi, path: string, token: string): Promise<Json[]> {
  const r = await api.do('GET', path, undefined, { token });
  expect(`${path} ${String(r.status)}`).toBe(`${path} 200`);
  return r.body?.items as Json[];
}

async function setStatus(api: TestApi, path: string, body: Json, token: string) {
  return api.do('POST', `${path}/status`, body, { token });
}

describe('admin people console', () => {
  let api: TestApi;
  let j: Job;
  let support: string;
  let superAdmin: AdminSession;

  const count = async (path: string) => (await items(api, path, support)).length;
  const summary = (r: { body?: Json }) => r.body?.summary as Json;

  beforeEach(async () => {
    api = await startTestApi();
  });

  async function start(provider: string, client: string) {
    j = await completedJob(api, provider, client);
    support = (await adminSession(api, ['support_agent'])).accessToken;
    superAdmin = await adminSession(api, ['super_admin']);
  }

  it('lists, shows and bans providers (TestPeople_ProvidersListDetailAndBan)', async () => {
    await start('01712345681', '01812345681');
    await enrolledProvider(api, '01712345682', 'female', service('electrician'));
    const queries: [string, number][] = [
      ['', 2],
      ['?status=pending', 1],
      ['?status=active&level=1&flagged=false', 1],
      ['?q=12345681', 1],
      ['?q=nobody%25', 0],
    ];
    for (const [q, want] of queries) {
      expect(`${q} ${String(await count(`/v1/admin/providers${q}`))}`).toBe(`${q} ${String(want)}`);
    }
    const first = await api.do('GET', '/v1/admin/providers?limit=1', undefined, { token: support });
    const cursor = first.body?.nextCursor as string;
    const rest = await items(api, `/v1/admin/providers?limit=1&cursor=${cursor}`, support);
    expect(rest.map((p) => p.id)).toEqual([j.provider.id]);
    const path = `/v1/admin/providers/${j.provider.id}`;
    const d = (await api.do('GET', path, undefined, { token: support })).body ?? {};
    expect(d).toMatchObject({
      gender: 'male',
      summary: { status: 'active', level: 1, online: true },
    });
    expect((d.summary as Json).services).toHaveLength(1);
    expect((d.items as unknown[]).length).toBeGreaterThanOrEqual(7);
    expect(d.recentBookings).toHaveLength(1);
    await banAndReinstate(path);
    await pendingProvider();
    for (const p of [`/v1/admin/providers/${uuid()}`, `/v1/admin/providers/${j.customer.id}`]) {
      expect((await api.do('GET', p, undefined, { token: support })).status).toBe(404);
      const ban = { status: 'banned', reason: 'Fraudulent documents' };
      expect((await setStatus(api, p, ban, superAdmin.accessToken)).status).toBe(404);
    }
    expect(
      (await api.do('GET', '/v1/admin/providers?cursor=%25', undefined, { token: support })).status,
    ).toBe(422);
    await closedPool(path, '/v1/admin/providers', { status: 'banned', reason: 'Closed' });
  });

  async function banAndReinstate(path: string) {
    const ban = { status: 'banned', reason: 'Fraudulent documents' };
    const banned = await setStatus(api, path, ban, superAdmin.accessToken);
    expect(summary(banned).status).toBe('banned');
    expect((await setStatus(api, path, ban, superAdmin.accessToken)).code).toBe('CONFLICT');
    await relayEvents(api);
    const profile = await api.do('GET', '/v1/provider/profile', undefined, {
      token: j.provider.token,
    });
    expect(profile.status).toBe(401);
    expect(await count('/v1/admin/providers?status=banned')).toBe(1);
    const d = (await api.do('GET', path, undefined, { token: support })).body ?? {};
    expect((d.summary as Json).online).toBe(false);
    expect(d.statusHistory).toEqual([expect.objectContaining({ actorId: superAdmin.id })]);
    const back = { status: 'active', reason: 'Appeal accepted' };
    expect(summary(await setStatus(api, path, back, superAdmin.accessToken)).status).toBe('active');
  }

  async function pendingProvider() {
    const [pending] = await items(api, '/v1/admin/providers?status=pending', support);
    const path = `/v1/admin/providers/${String(pending?.id)}`;
    const suspend = { status: 'suspended', reason: 'Checking' };
    expect(summary(await setStatus(api, path, suspend, superAdmin.accessToken)).status).toBe(
      'suspended',
    );
    const back = { status: 'active', reason: 'Checked' };
    expect(summary(await setStatus(api, path, back, superAdmin.accessToken)).status).toBe(
      'pending',
    );
    const verifier = (await adminSession(api, ['verifier'])).accessToken;
    const reject = `/v1/admin/verifications/${String(pending?.id)}/items/selfie/reject`;
    await api.do('POST', reject, { reason: 'Face not visible' }, { token: verifier });
    expect((await api.do('GET', path, undefined, { token: support })).text).toContain(
      'Face not visible',
    );
  }

  async function closedPool(path: string, list: string, body: Json) {
    await api.app.get<Database>(DATABASE).close();
    const calls: [string, string][] = [
      ['GET', list],
      ['GET', path],
      ['POST', `${path}/status`],
    ];
    for (const [method, p] of calls) {
      const r = await api.do(method, p, method === 'GET' ? undefined : body, {
        token: superAdmin.accessToken,
      });
      expect(`${method} ${p} ${String(r.status)}`).toBe(`${method} ${p} 500`);
    }
  }

  it('lists, shows and suspends customers (TestPeople_CustomersListDetailAndSuspend)', async () => {
    await start('01712345683', '01812345683');
    await customer(api, '01812345684');
    const late = { reason: 'late', description: 'Arrived two hours late.' };
    await api.do('POST', `/v1/customer/bookings/${j.id}/reports`, late, {
      token: j.customer.token,
    });
    const queries: [string, number][] = [
      ['', 2],
      ['?q=nusrat', 2],
      ['?q=12345684', 1],
      ['?status=suspended', 0],
    ];
    for (const [q, want] of queries) {
      expect(`${q} ${String(await count(`/v1/admin/customers${q}`))}`).toBe(`${q} ${String(want)}`);
    }
    const first = await api.do('GET', '/v1/admin/customers?limit=1', undefined, { token: support });
    const cursor = first.body?.nextCursor as string;
    expect(await items(api, `/v1/admin/customers?limit=1&cursor=${cursor}`, support)).toHaveLength(
      1,
    );
    await relayEvents(api);
    const path = `/v1/admin/customers/${j.customer.id}`;
    const d = (await api.do('GET', path, undefined, { token: support })).body ?? {};
    expect(d).toMatchObject({ summary: { bookings: 1, status: 'active' } });
    expect(d.recentBookings).toHaveLength(1);
    expect(d.complaints).toHaveLength(1);
    await api.do(
      'POST',
      `/v1/provider/jobs/${j.id}/review`,
      { stars: 4 },
      { token: j.provider.token },
    );
    const suspend = { status: 'suspended', reason: 'Abusive messages' };
    const r = await setStatus(api, path, suspend, superAdmin.accessToken);
    expect(summary(r)).toMatchObject({ status: 'suspended', rating: 4 });
    await relayEvents(api);
    expect(await count('/v1/admin/customers?status=suspended')).toBe(1);
    const again = { status: 'suspended', reason: 'Again' };
    expect((await setStatus(api, path, again, superAdmin.accessToken)).status).toBe(409);
    for (const p of [`/v1/admin/customers/${uuid()}`, `/v1/admin/customers/${j.provider.id}`]) {
      expect((await api.do('GET', p, undefined, { token: support })).status).toBe(404);
      const ban = { status: 'banned', reason: 'Nope' };
      expect((await setStatus(api, p, ban, superAdmin.accessToken)).status).toBe(404);
    }
    expect(
      (await api.do('GET', '/v1/admin/customers?cursor=%25', undefined, { token: support })).status,
    ).toBe(422);
    for (const name of ['booking.BookingRequested', 'identity.AccountStatusChanged']) {
      const broken = { ...envelope(api, { name }), payload: '{' };
      await expect(subscribedBus(api).dispatch(broken as never)).rejects.toThrow();
    }
    await closedPool(path, '/v1/admin/customers', { status: 'active', reason: 'Closed' });
  });
});
