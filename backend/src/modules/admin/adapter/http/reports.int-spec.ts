import { v7 as uuid } from 'uuid';
import { startTestApi, type TestApi } from '../../../../../test/kit/api';
import { customer, type Job, requestedJob } from '../../../../../test/kit/booking';
import { relayEvents } from '../../../../../test/kit/events';
import { adminSession, type AdminSession } from '../../../../../test/kit/identity';
import { upload } from '../../../../../test/kit/media';
import { DATABASE, type Database } from '../../../../platform/db/database';
import { AUDIT_SERVICE, type AuditService } from '../../../audit/contract/audit-service';
import { ADMIN_SERVICE, type AdminService } from '../../contract/admin-service';

type Json = Record<string, unknown>;

async function report(api: TestApi, path: string, body: Json, token: string): Promise<Json> {
  const r = await api.do('POST', path, body, { token });
  if (r.status !== 201) {
    throw new Error(`report ${path}: ${String(r.status)} ${r.text}`);
  }
  return r.body ?? {};
}

/** Assigns, comments and resolves a complaint as `agent`, checking it resolves once. */
async function resolve(api: TestApi, agent: AdminSession, id: string): Promise<Json> {
  const auth = { token: agent.accessToken };
  const base = `/v1/admin/complaints/${id}`;
  const assigned = await api.do('POST', `${base}/assign`, { assigneeId: agent.id }, auth);
  expect(assigned.body?.assigneeId).toBe(agent.id);
  expect(
    (await api.do('POST', `${base}/comments`, { body: 'Called the provider.' }, auth)).status,
  ).toBe(201);
  const body = { resolution: 'Provider warned; partial refund agreed.', verified: true };
  const r = await api.do('POST', `${base}/resolve`, body, auth);
  const again = { resolution: 'Second attempt.', verified: false };
  expect((await api.do('POST', `${base}/resolve`, again, auth)).code).toBe(
    'COMPLAINT_INVALID_TRANSITION',
  );
  expect((await api.do('POST', `${base}/assign`, { assigneeId: agent.id }, auth)).status).toBe(409);
  return r.body ?? {};
}

describe('complaints reported on real bookings', () => {
  let api: TestApi;
  let j: Job;

  beforeEach(async () => {
    api = await startTestApi();
    j = await requestedJob(api, '01712345661', '01812345661');
  });

  it('takes reports from both sides and resolves them (TestComplaints_ReportedByBothSidesAndResolved)', async () => {
    const photo = await upload(api, j.customer.id, 'customer', 'complaint_photo');
    const late = { reason: 'late', description: 'Arrived two hours late.', photoMediaIds: [photo] };
    const mine = await report(api, `/v1/customer/bookings/${j.id}/reports`, late, j.customer.token);
    expect(mine).toMatchObject({
      againstId: j.provider.id,
      status: 'open',
      photoMediaIds: [photo],
    });
    expect(mine.ticketNumber).toMatch(/^TCK-/);
    const unavailable = {
      reason: 'customer_unavailable',
      description: 'Nobody answered the door.',
    };
    const theirs = await report(
      api,
      `/v1/provider/jobs/${j.id}/reports`,
      unavailable,
      j.provider.token,
    );
    expect(theirs).toMatchObject({ againstId: j.customer.id, reporterRole: 'provider' });
    await refusals(api, j, late);
    const agent = await adminSession(api, ['support_agent']);
    const resolved = await resolve(api, agent, mine.id as string);
    expect(resolved).toMatchObject({ status: 'resolved', verified: true });
    expect(resolved.comments).toHaveLength(1);
    await relayEvents(api);
    const db = api.app.get<Database>(DATABASE);
    const flags = await db.query<{ flagged_for_review: boolean }>(
      'SELECT flagged_for_review FROM provider.providers WHERE id = $1',
      [j.provider.id],
    );
    expect(flags.rows[0]?.flagged_for_review).toBe(true);
    expect(
      await api.app.get<AdminService>(ADMIN_SERVICE).countVerifiedComplaints(j.provider.id),
    ).toBe(1);
    const inbox = await api.do('GET', '/v1/customer/notifications', undefined, {
      token: j.customer.token,
    });
    expect(inbox.text).toContain(`Your report ${mine.ticketNumber as string} has been resolved.`);
    const audit = api.app.get<AuditService>(AUDIT_SERVICE);
    const entries = await audit.listForSubject('complaint', mine.id as string, 10);
    expect(entries).toEqual([
      expect.objectContaining({ action: 'complaint.resolved', actorId: agent.id }),
    ]);
  });

  it('answers 500 for a report once the database is gone (TestComplaints_QueueFiltersAndErrors)', async () => {
    await api.app.get<Database>(DATABASE).close();
    const body = { reason: 'late', description: 'Arrived two hours late.' };
    const r = await api.do('POST', `/v1/customer/bookings/${j.id}/reports`, body, {
      token: j.customer.token,
    });
    expect(r.status).toBe(500);
  });
});

async function refusals(api: TestApi, j: Job, late: Json) {
  const stranger = (await customer(api, '01812345662')).customer;
  const asCustomer = await api.token(j.provider.id, ['customer']);
  const mine = `/v1/customer/bookings/${j.id}/reports`;
  const cases: [string, string, Json, string, string][] = [
    ['stranger', mine, late, stranger.token, 'NOT_FOUND'],
    [
      'unknown booking',
      `/v1/customer/bookings/${uuid()}/reports`,
      late,
      j.customer.token,
      'NOT_FOUND',
    ],
    ['provider as customer', mine, late, asCustomer, 'NOT_FOUND'],
    [
      'blank description',
      mine,
      { reason: 'late', description: '    late     ' },
      j.customer.token,
      'VALIDATION_FAILED',
    ],
    ['used photo', `/v1/provider/jobs/${j.id}/reports`, late, j.provider.token, 'UPLOAD_INVALID'],
    [
      'unknown photo',
      mine,
      { ...late, photoMediaIds: [uuid()] },
      j.customer.token,
      'UPLOAD_INVALID',
    ],
  ];
  for (const [name, path, body, token, code] of cases) {
    const r = await api.do('POST', path, body, { token });
    expect(`${name} ${String(r.code)}`).toBe(`${name} ${code}`);
  }
}
