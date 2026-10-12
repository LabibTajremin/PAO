import { randomUUID } from 'node:crypto';
import { startTestApi, type TestApi } from '../../../../../test/kit/api';
import { relayEvents } from '../../../../../test/kit/events';
import { adminSession, signIn } from '../../../../../test/kit/identity';
import { DATABASE, type Database } from '../../../../platform/db/database';
import { checkRoutesAgainstSpec } from '../../../../platform/http/route-spec-check';
import { OPENAPI_DOCUMENT } from '../../../../platform/http/spec-routes';
import { HEALTH_ROUTES } from '../../../../platform/health/health';
import { IDENTITY_SERVICE, type IdentityService } from '../../../identity/contract';
import { AUDIT_SERVICE, type AuditService } from '../../contract';

const entry = (over: Partial<Parameters<AuditService['record']>[0]>) => ({
  id: '',
  at: new Date(),
  actorId: null,
  actorRole: '',
  action: 'system.note',
  subjectType: 'system',
  subjectId: 's',
  reason: '',
  before: null,
  after: null,
  ...over,
});

describe('audit', () => {
  let api: TestApi;
  let audit: AuditService;
  let token: string;

  beforeEach(async () => {
    api = await startTestApi();
    audit = api.app.get<AuditService>(AUDIT_SERVICE);
    token = (await adminSession(api, ['super_admin'])).accessToken;
  });

  it('serves the audit viewer with the spec permission', () => {
    const report = checkRoutesAgainstSpec(api.app, api.app.get(OPENAPI_DOCUMENT), HEALTH_ROUTES);
    expect(report.mismatched).toEqual([]);
    expect(report.unserved.filter((op) => op.includes('/v1/admin/audit'))).toEqual([]);
  });

  it('turns events into entries once, even when they are redelivered', async () => {
    const superId = randomUUID();
    const customer = await signIn(api, '01712345678', 'customer');
    await api.app.get<IdentityService>(IDENTITY_SERVICE).setAccountStatus({
      accountId: customer.account.id,
      status: 'suspended',
      reason: 'abuse',
      actorId: superId,
    });
    await relayEvents(api);
    await api.app.get<Database>(DATABASE).query('UPDATE identity.outbox SET published_at = NULL');
    await relayEvents(api);
    const q = `action=account.status_changed&subjectId=${customer.account.id}`;
    const r = await api.do('GET', `/v1/admin/audit?${q}`, undefined, { token });
    expect(r.body?.items).toEqual([expect.objectContaining({ reason: 'abuse' })]);
    const history = await audit.listForSubject('account', customer.account.id, 10);
    expect(history).toHaveLength(1);
    expect(history[0]?.actorId).toBe(superId);
  });

  it('pages and filters, stays append-only and reports a lost database', async () => {
    const actor = randomUUID();
    const base = new Date('2026-10-01T00:00:00Z');
    for (let i = 0; i < 3; i++) {
      await audit.record(
        entry({
          at: new Date(base.getTime() + i * 3_600_000),
          actorId: actor,
          actorRole: 'verifier',
          action: 'verification.item_approved',
          subjectType: 'provider',
          subjectId: 'p1',
          before: { a: 1 },
          after: { b: 2 },
        }),
      );
    }
    const q = new URLSearchParams({
      actorId: actor,
      limit: '2',
      from: base.toISOString(),
      to: new Date(base.getTime() + 5 * 3_600_000).toISOString(),
    });
    const first = await api.do('GET', `/v1/admin/audit?${q.toString()}`, undefined, { token });
    expect(first.body?.items).toHaveLength(2);
    q.set('cursor', first.body?.nextCursor as string);
    const second = await api.do('GET', `/v1/admin/audit?${q.toString()}`, undefined, { token });
    expect(second.body?.items).toHaveLength(1);
    expect(second.body?.nextCursor).toBeUndefined();
    const bad = await api.do('GET', '/v1/admin/audit?cursor=%25%25', undefined, { token });
    expect(bad.status).toBe(422);
    const db = api.app.get<Database>(DATABASE);
    for (const stmt of [
      "UPDATE audit.entries SET reason = 'x'",
      'DELETE FROM audit.entries',
      'TRUNCATE audit.entries',
    ]) {
      await expect(db.query(stmt)).rejects.toThrow();
    }
    await db.close();
    const lost = await api.do('GET', '/v1/admin/audit', undefined, { token, unchecked: true });
    expect(lost.status).toBe(500);
  });

  it('leaves out what a sparse entry does not have', async () => {
    await audit.record(entry({}));
    const r = await api.do('GET', '/v1/admin/audit?subjectId=s', undefined, { token });
    const item = (r.body?.items as Record<string, unknown>[])[0];
    expect(item?.before).toBeUndefined();
    expect(item?.actorRole).toBeUndefined();
  });
});
