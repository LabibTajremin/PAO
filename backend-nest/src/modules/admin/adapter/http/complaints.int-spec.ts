import { v7 as uuid } from 'uuid';
import { startTestApi, type TestApi } from '../../../../../test/kit/api';
import { adminSession, type AdminSession, signIn } from '../../../../../test/kit/identity';
import { DATABASE, type Database } from '../../../../platform/db/database';
import { ticketNumber } from '../../domain/complaint';
import { COMPLAINT_REPOSITORY, type ComplaintRepository } from '../../port/complaint-repository';

// Reports need a booking and media, so these specs seed the queue directly; the report
// journey (Go TestComplaints_ReportedByBothSidesAndResolved) waits for booking.
async function seedComplaint(db: Database, at: Date, reason: string): Promise<string> {
  const id = uuid();
  await db.query(
    `INSERT INTO admin.complaints (id, booking_id, reporter_id, reporter_role, against_id, reason,
       description, created_at, updated_at) VALUES ($1, $2, $3, 'customer', $4, $5, $6, $7, $7)`,
    [id, uuid(), uuid(), uuid(), reason, 'Something went wrong here.', at],
  );
  return id;
}

describe('admin complaints queue', () => {
  let api: TestApi;
  let db: Database;
  let agent: AdminSession;
  let auth: { token: string };
  let customerId: string;
  let newest: string;

  beforeAll(async () => {
    api = await startTestApi();
    db = api.app.get(DATABASE);
    const start = api.clock.now().getTime();
    for (const [i, reason] of ['late', 'overcharge', 'damage'].entries()) {
      newest = await seedComplaint(db, new Date(start + i * 1000), reason);
    }
    agent = await adminSession(api, ['support_agent']);
    auth = { token: agent.accessToken };
    const customer = await signIn(api, '+8801712345663', 'customer');
    customerId = (await api.do('GET', '/v1/me', undefined, { token: customer.accessToken })).body
      ?.id as string;
  });

  it('pages the queue newest first', async () => {
    const first = await api.do('GET', '/v1/admin/complaints?status=open&limit=2', undefined, auth);
    const items = first.body?.items as { id: string; reason: string }[];
    expect(items.map((c) => c.reason)).toEqual(['damage', 'overcharge']);
    const cursor = first.body?.nextCursor as string;
    const rest = await api.do(
      'GET',
      `/v1/admin/complaints?status=open&limit=2&cursor=${cursor}`,
      undefined,
      auth,
    );
    expect(rest.body?.items).toHaveLength(1);
    expect(rest.body?.nextCursor).toBeUndefined();
  });

  it.each([
    ['assign a customer', 'assign', () => ({ assigneeId: customerId })],
    ['assign an unknown id', 'assign', () => ({ assigneeId: uuid() })],
    ['resolve with a short note', 'resolve', () => ({ resolution: '  ok   ', verified: false })],
  ])('refuses to %s', async (_name, action, body) => {
    const r = await api.do('POST', `/v1/admin/complaints/${newest}/${action}`, body(), auth);
    expect(r.status).toBe(422);
  });

  it.each([
    ['assign', () => ({ assigneeId: agent.id })],
    ['comments', () => ({ body: 'x' })],
    ['resolve', () => ({ resolution: 'Done here.', verified: false })],
  ])('answers 404 for %s on a missing complaint', async (action, body) => {
    const r = await api.do('POST', `/v1/admin/complaints/${uuid()}/${action}`, body(), auth);
    expect(r.status).toBe(404);
  });

  it('answers 404 for a missing complaint and 422 for a bad cursor', async () => {
    expect((await api.do('GET', `/v1/admin/complaints/${uuid()}`, undefined, auth)).status).toBe(
      404,
    );
    expect((await api.do('GET', '/v1/admin/complaints?cursor=%25', undefined, auth)).status).toBe(
      422,
    );
  });

  it('assigns, comments and resolves once, and publishes the resolution', async () => {
    const base = `/v1/admin/complaints/${newest}`;
    const assigned = await api.do('POST', `${base}/assign`, { assigneeId: agent.id }, auth);
    expect(assigned).toMatchObject({ status: 200, body: { assigneeId: agent.id } });
    const mine = await api.do(
      'GET',
      `/v1/admin/complaints?assigneeId=${agent.id}`,
      undefined,
      auth,
    );
    expect(mine.body?.items).toHaveLength(1);
    expect((await api.do('GET', base, undefined, auth)).body?.status).toBe('assigned');
    const noted = await api.do('POST', `${base}/comments`, { body: 'Called the provider.' }, auth);
    expect(noted.status).toBe(201);
    const body = { resolution: 'Provider warned; partial refund agreed.', verified: true };
    const r = await api.do('POST', `${base}/resolve`, body, auth);
    expect(r.body).toMatchObject({ status: 'resolved', verified: true });
    expect(r.body?.comments).toHaveLength(1);
    const again = { resolution: 'Second attempt.', verified: false };
    expect((await api.do('POST', `${base}/resolve`, again, auth)).code).toBe(
      'COMPLAINT_INVALID_TRANSITION',
    );
    expect((await api.do('POST', `${base}/assign`, { assigneeId: agent.id }, auth)).status).toBe(
      409,
    );
    const events = await db.query<{ payload: { verified: boolean; actorId: string } }>(
      `SELECT payload FROM admin.outbox WHERE event_name = 'admin.ComplaintResolved'`,
    );
    expect(events.rows.map((e) => e.payload)).toMatchObject([
      { verified: true, actorId: agent.id },
    ]);
  });

  it('stores reports with ticket numbers and finds them by person', async () => {
    const repo = api.app.get<ComplaintRepository>(COMPLAINT_REPOSITORY, { strict: false });
    const [reporterId, againstId] = [uuid(), uuid()];
    const now = api.clock.now();
    const c = await repo.createComplaint(
      {
        id: uuid(),
        bookingId: uuid(),
        reporterId,
        reporterRole: 'provider',
        againstId,
        reason: 'payment',
        description: 'The customer did not pay.',
        photos: [],
        status: 'open',
        assigneeId: null,
        resolution: '',
        verified: false,
        createdAt: now,
        updatedAt: now,
        resolvedAt: null,
      },
      (stored) => ({ name: 'admin.ComplaintCreated', ticket: ticketNumber(stored) }),
    );
    expect(ticketNumber(c)).toMatch(/^TCK-\d{6}$/);
    expect((await repo.complaintsInvolving(reporterId, 10)).map((x) => x.id)).toEqual([c.id]);
    expect(await repo.complaintsInvolving(againstId, 10)).toHaveLength(1);
    expect(await repo.countComplaintsAgainst(againstId)).toBe(1);
    expect(await repo.countVerifiedComplaints(againstId)).toBe(0);
  });

  it('answers 500 once the database is gone', async () => {
    await db.close();
    const body = { assigneeId: uuid(), body: 'note', resolution: 'Closed now.', verified: false };
    const base = `/v1/admin/complaints/${newest}`;
    for (const [method, path] of [
      ['GET', '/v1/admin/complaints'],
      ['GET', base],
      ['POST', `${base}/assign`],
      ['POST', `${base}/comments`],
      ['POST', `${base}/resolve`],
    ] as const) {
      const r = await api.do(method, path, method === 'GET' ? undefined : body, auth);
      expect(`${method} ${path} ${String(r.status)}`).toBe(`${method} ${path} 500`);
    }
  });
});
