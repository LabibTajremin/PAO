import { decodeCursor } from '../../../../platform/http/cursor';
import { type Principal } from '../../../../platform/http/principal';
import { type AuditEntry } from '../../../audit/contract/dto';
import { type CustomerRecord } from '../../../customer/contract/admin-search';
import { type ProviderRecord } from '../../../provider/contract/admin-search';
import { type CustomerConsole, type CustomerDetail } from '../../app/customer-console';
import { type ProviderConsole, type ProviderDetail } from '../../app/provider-console';
import { type ReadDashboard } from '../../app/read-dashboard';
import { type ReportProblem } from '../../app/report-problem';
import { type Complaint, type ComplaintReport } from '../../domain/complaint';
import { CustomerReportsController, ProviderReportsController } from './complaints.controller';
import { DashboardController } from './dashboard.controller';
import { AdminCustomersController, AdminProvidersController } from './people.controller';

const at = new Date('2026-10-09T10:00:00Z');
const me = { accountId: 'me' } as Principal;
const id = '0192f5a0-0000-7000-8000-000000000001';

const provider = (n: number): ProviderRecord => ({
  id: `0192f5a0-0000-7000-8000-00000000000${String(n)}`,
  name: 'Karim',
  phone: '+8801712345681',
  status: 'active',
  level: 1,
  serviceIds: ['s1'],
  rating: 4.5,
  ratingCount: 2,
  completedJobs: 3,
  flagged: false,
  flagReason: '',
  online: true,
  createdAt: at,
});
const customer: CustomerRecord = {
  id,
  name: 'Nusrat',
  phone: '+8801812345681',
  status: 'active',
  bookings: 1,
  createdAt: at,
};
const entry: AuditEntry = {
  id: 'e1',
  at,
  actorId: 'a1',
  actorRole: 'super_admin',
  action: 'account.status_changed',
  subjectType: 'account',
  subjectId: id,
  reason: 'Fraud',
  before: { status: 'active' },
  after: { status: 'banned' },
};
const complaint: Complaint = {
  id,
  ticket: 1001,
  bookingId: 'b1',
  reporterId: 'me',
  reporterRole: 'customer',
  againstId: 'p1',
  reason: 'late',
  description: 'Arrived two hours late.',
  photos: [],
  status: 'resolved',
  assigneeId: 'agent',
  resolution: 'Warned.',
  verified: true,
  createdAt: at,
  updatedAt: at,
  resolvedAt: at,
  comments: [],
};
const booking = {
  id: 'b1',
  number: 'PAO-104233',
  status: 'completed' as const,
  serviceName: { en: 'Electrician', bn: 'ইলেকট্রিশিয়ান' },
  totalPaisa: 50_000,
  createdAt: at,
};

describe('admin people controllers', () => {
  it('pages providers with their services', async () => {
    const queries: unknown[] = [];
    const console = {
      list: (q: unknown) =>
        Promise.resolve(void queries.push(q)).then(() => [provider(1), provider(2)]),
      services: () => Promise.resolve([{ id: 's1', name: { en: 'E', bn: 'ই' } }]),
    } as unknown as ProviderConsole;
    const c = new AdminProvidersController(console);
    const r = await c.list({ limit: 1, q: 'kar', status: 'active', level: 1, flagged: false });
    expect(r.items).toHaveLength(1);
    expect(r.items[0]?.services).toEqual([{ id: 's1', name: { en: 'E', bn: 'ই' } }]);
    expect(decodeCursor(r.nextCursor)?.id).toBe(provider(1).id);
    const last = await c.list({ cursor: r.nextCursor });
    expect(last.nextCursor).toBeUndefined();
    expect(queries[1]).toMatchObject({ text: '', afterId: provider(1).id, level: null });
  });

  it('shows provider details', async () => {
    const detail: ProviderDetail = {
      record: provider(1),
      services: [],
      profile: { gender: 'male', experienceYears: 3 } as ProviderDetail['profile'],
      items: [
        {
          type: 'selfie',
          status: 'rejected',
          reason: 'Blurred',
          required: true,
          decidedAt: at,
          expiresAt: at,
        },
        {
          type: 'nid',
          status: 'pending',
          reason: '',
          required: true,
          decidedAt: null,
          expiresAt: null,
        },
      ],
      recent: [booking],
      complaints: 1,
      cancellations30d: 0,
      history: [entry, { ...entry, actorId: null, before: null, after: null }],
    };
    const console = {
      detail: () => Promise.resolve(detail),
      setStatus: () => Promise.resolve(detail),
    } as unknown as ProviderConsole;
    const c = new AdminProvidersController(console);
    const d = await c.get(id);
    expect(d.items[0]).toMatchObject({ rejectionReason: 'Blurred' });
    expect(d.items[1]).toEqual({ type: 'nid', status: 'pending', required: true });
    expect(d.statusHistory[1]).not.toHaveProperty('actorId');
    expect(d.recentBookings[0]).toMatchObject({ total: 50_000 });
    expect(await c.setStatus(me, id, { status: 'banned', reason: 'Fraud' })).toEqual(d);
  });

  it('pages customers and shows their rating once rated', async () => {
    const detail: CustomerDetail = {
      record: customer,
      rating: { average: 4, count: 1, distribution: [0, 0, 0, 1, 0] },
      recent: [],
      complaints: [complaint, { ...complaint, assigneeId: null, resolvedAt: null }],
      history: [],
    };
    const console = {
      list: () => Promise.resolve([customer]),
      detail: () => Promise.resolve(detail),
      setStatus: () => Promise.resolve({ ...detail, rating: { ...detail.rating, count: 0 } }),
    } as unknown as CustomerConsole;
    const c = new AdminCustomersController(console);
    expect(await c.list({})).toEqual({ items: [expect.objectContaining({ name: 'Nusrat' })] });
    const d = await c.get(id);
    expect(d.summary.rating).toBe(4);
    expect(d.complaints[0]).toMatchObject({ assigneeId: 'agent', ticketNumber: 'TCK-001001' });
    expect(d.complaints[1]).not.toHaveProperty('resolvedAt');
    const changed = await c.setStatus(me, id, { status: 'suspended', reason: 'Abuse' });
    expect(changed.summary).not.toHaveProperty('rating');
  });
});

describe('report and dashboard controllers', () => {
  it('files reports in the caller role', async () => {
    const seen: ComplaintReport[] = [];
    const problems = {
      execute: (r: ComplaintReport) => Promise.resolve(void seen.push(r)).then(() => complaint),
    } as unknown as ReportProblem;
    const body = { reason: 'late' as const, description: 'Arrived two hours late.' };
    await new CustomerReportsController(problems).create(me, 'b1', body);
    await new ProviderReportsController(problems).create(me, 'b1', {
      ...body,
      photoMediaIds: ['x'],
    });
    expect(seen.map((r) => [r.reporterRole, r.photos])).toEqual([
      ['customer', []],
      ['provider', ['x']],
    ]);
  });

  it('shows the dashboard', async () => {
    const dashboard = {
      execute: () =>
        Promise.resolve({
          providersByStatus: { active: 1 },
          providersByLevel: { '1': 1 },
          bookingsPerDay: [{ date: '2026-10-09', total: 1, completed: 1 }],
          completionRate: 1,
          openComplaints: 0,
          pendingVerifications: 2,
          generatedAt: at,
        }),
    } as unknown as ReadDashboard;
    const d = await new DashboardController(dashboard).get();
    expect(d).toMatchObject({ generatedAt: at.toISOString(), pendingVerifications: 2 });
  });
});
