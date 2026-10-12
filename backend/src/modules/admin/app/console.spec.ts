import { FakeClock } from '../../../platform/clock/fake-clock';
import { DomainError } from '../../../platform/errors/domain-error';
import { type CustomerRecord } from '../../customer/contract/admin-search';
import { type ProviderRecord } from '../../provider/contract/admin-search';
import { type Complaint } from '../domain/complaint';
import { type ComplaintRepository } from '../port/complaint-repository';
import { type CachedValue, type Console } from '../port/console';
import { type DashboardRepository } from '../port/dashboard-repository';
import { CustomerConsole } from './customer-console';
import { ProviderConsole } from './provider-console';
import { type CachedDashboard, dhakaDate, ReadDashboard } from './read-dashboard';

const boom = new Error('boom');
const created = new Date('2026-10-01T00:00:00Z');
const provider: ProviderRecord = {
  id: 'p1',
  name: 'Karim',
  phone: '+8801712345681',
  status: 'active',
  level: 0,
  serviceIds: ['s1', 'gone'],
  rating: 0,
  ratingCount: 0,
  completedJobs: 0,
  flagged: false,
  flagReason: '',
  online: true,
  createdAt: created,
};
const customer: CustomerRecord = {
  id: 'c1',
  name: 'Nusrat',
  phone: '+8801812345681',
  status: 'active',
  bookings: 1,
  createdAt: created,
};

function fakeConsole() {
  const statusChanges: unknown[] = [];
  const console = {
    providers: () => ({
      searchProviders: (q: { id: string | null }) =>
        Promise.resolve(q.id === null || q.id === 'p1' ? [provider] : []),
      getProvider: () => Promise.resolve({ gender: 'male', experienceYears: 3 }),
    }),
    customers: () => ({
      searchCustomers: (q: { id: string | null }) =>
        Promise.resolve(q.id === null || q.id === 'c1' ? [customer] : []),
    }),
    catalog: () => ({
      getService: (id: string) =>
        id === 's1' ? Promise.resolve({ id: 's1' }) : Promise.reject(boom),
    }),
    verification: () => ({
      getItems: () => Promise.resolve([]),
      countPendingReviews: () => Promise.resolve(4),
    }),
    bookings: () => ({
      listRecentBookings: () => Promise.resolve([]),
      getProviderStats: () => Promise.resolve({ completedJobs: 0, cancellations30d: 2 }),
    }),
    ratings: () => ({ getCustomerRating: () => Promise.resolve({ average: 4, count: 1 }) }),
    audit: () => ({ listForSubject: () => Promise.resolve([]) }),
    identity: () => ({
      setAccountStatus: (input: unknown) => Promise.resolve(void statusChanges.push(input)),
    }),
  } as unknown as Console;
  return { console, statusChanges };
}

const complaints = {
  countComplaintsAgainst: () => Promise.resolve(3),
  complaintsInvolving: () => Promise.resolve([{ id: 'x' } as Complaint]),
} as unknown as ComplaintRepository;

async function reason(p: Promise<unknown>): Promise<string | undefined> {
  const err = await p.then(
    () => undefined,
    (e: unknown) => e,
  );
  return err instanceof DomainError ? err.reason : undefined;
}

describe('provider console', () => {
  it('lists, details and changes status', async () => {
    const { console, statusChanges } = fakeConsole();
    const providers = new ProviderConsole(console, complaints);
    expect(await providers.list({ id: null } as never)).toEqual([provider]);
    const d = await providers.detail('p1');
    expect(d).toMatchObject({ complaints: 3, cancellations30d: 2, services: [{ id: 's1' }] });
    const change = { actorId: 'a', accountId: 'p1', status: 'active', reason: 'Checked' } as const;
    expect((await providers.setStatus(change)).record.status).toBe('pending');
    expect(statusChanges).toEqual([change]);
    const banned = await providers.setStatus({ ...change, status: 'banned' });
    expect(banned.record.status).toBe('banned');
    expect(await reason(providers.detail('nobody'))).toBe('admin.person_not_found');
    expect(await reason(providers.setStatus({ ...change, accountId: 'nobody' }))).toBe(
      'admin.person_not_found',
    );
  });
});

describe('customer console', () => {
  it('lists, details and changes status', async () => {
    const { console } = fakeConsole();
    const customers = new CustomerConsole(console, complaints);
    expect(await customers.list({ id: null } as never)).toEqual([customer]);
    const d = await customers.detail('c1');
    expect(d).toMatchObject({ rating: { average: 4 }, complaints: [{ id: 'x' }] });
    const change = { actorId: 'a', accountId: 'c1', status: 'suspended', reason: 'Abuse' } as const;
    expect((await customers.setStatus(change)).record.status).toBe('suspended');
    expect(await reason(customers.detail('nobody'))).toBe('admin.person_not_found');
    expect(await reason(customers.setStatus({ ...change, accountId: 'nobody' }))).toBe(
      'admin.person_not_found',
    );
  });
});

describe('dashboard', () => {
  it('uses the Dhaka date', () => {
    expect(dhakaDate(new Date('2026-10-11T18:30:00Z'))).toBe('2026-10-12');
    expect(dhakaDate(new Date('2026-10-11T17:59:00Z'))).toBe('2026-10-11');
  });

  it('builds the numbers once a minute and passes failures on', async () => {
    const clock = new FakeClock(new Date('2026-10-09T20:00:00Z'));
    let since = '';
    let down = false;
    const repo: DashboardRepository = {
      dashboard: (s) => {
        since = s;
        return down
          ? Promise.reject(boom)
          : Promise.resolve({
              providersByStatus: { active: 1 },
              providersByLevel: { '0': 1 },
              openComplaints: 2,
              days: [{ date: s, total: 4, completed: 3 }],
            });
      },
    };
    let stored: CachedDashboard | undefined;
    const cache: CachedValue<CachedDashboard> = {
      read: () => Promise.resolve(stored),
      write: (v) => Promise.resolve(void (stored = v)),
      invalidate: () => Promise.resolve(),
    };
    const dashboard = new ReadDashboard(repo, fakeConsole().console, cache, clock);
    const d = await dashboard.execute();
    expect(since).toBe('2026-09-11');
    expect(d).toMatchObject({ pendingVerifications: 4, openComplaints: 2, completionRate: 0.75 });
    expect(d.bookingsPerDay[0]?.date).toBe(since);
    expect(d.bookingsPerDay.at(-1)?.date).toBe('2026-10-10');
    down = true;
    expect(await dashboard.execute()).toEqual(d);
    stored = undefined;
    await expect(dashboard.execute()).rejects.toBe(boom);
  });
});
