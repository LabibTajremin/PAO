import type Redis from 'ioredis';
import { v7 as uuid } from 'uuid';
import { startTestApi } from '../../../../../test/kit/api';
import { completedJob, requestedJob } from '../../../../../test/kit/booking';
import { deliver, envelope, relayEvents, subscribedBus } from '../../../../../test/kit/events';
import { adminSession } from '../../../../../test/kit/identity';
import { enrolledProvider, service } from '../../../../../test/kit/provider';
import { DATABASE, type Database } from '../../../../platform/db/database';
import { type DomainEvent } from '../../../../platform/events/domain-event';
import { REDIS } from '../../../../platform/redis/redis-client';
import { IDENTITY_SERVICE, type IdentityService } from '../../../identity/contract';
import { dhakaDate } from '../../app/read-dashboard';

describe('admin dashboard (TestDashboard_CountsFromEvents)', () => {
  it('counts from events and serves the cached copy', async () => {
    const api = await startTestApi();
    const done = await completedJob(api, '01712345671', '01812345671');
    const open = await requestedJob(api, '01712345672', '01812345672');
    await enrolledProvider(api, '01712345673', 'female', service('electrician'));
    const identity = api.app.get<IdentityService>(IDENTITY_SERVICE);
    for (const accountId of [open.provider.id, open.customer.id]) {
      await identity.setAccountStatus({
        accountId,
        status: 'suspended',
        reason: 'Testing',
        actorId: null,
      });
    }
    const late = { reason: 'late', description: 'Arrived two hours late.' };
    const filed = await api.do('POST', `/v1/customer/bookings/${done.id}/reports`, late, {
      token: done.customer.token,
    });
    expect(filed.status).toBe(201);
    await relayEvents(api);
    await deliver(api, { name: 'identity.AccountDeleted', accountId: uuid() } as DomainEvent);
    const broken = { ...envelope(api, { name: 'identity.AccountCreated' }), payload: '{' };
    await expect(subscribedBus(api).dispatch(broken as never)).rejects.toThrow();
    const auth = { token: (await adminSession(api, ['support_agent'])).accessToken };
    const d = (await api.do('GET', '/v1/admin/dashboard', undefined, auth)).body ?? {};
    expect(d).toMatchObject({
      providersByStatus: { active: 1, pending: 1, suspended: 1 },
      providersByLevel: { 0: 1, 1: 2 },
      completionRate: 0.5,
      openComplaints: 1,
      pendingVerifications: 1,
    });
    const days = d.bookingsPerDay as { date: string; total: number; completed: number }[];
    expect(days).toHaveLength(30);
    expect(days.at(-1)).toEqual({ date: dhakaDate(api.clock.now()), total: 2, completed: 1 });
    await api.app.get<Database>(DATABASE).close();
    expect((await api.do('GET', '/v1/admin/dashboard', undefined, auth)).status).toBe(200);
    await api.app.get<Redis>(REDIS).del(api.keys.key('cache', 'dashboard'));
    expect((await api.do('GET', '/v1/admin/dashboard', undefined, auth)).status).toBe(500);
  });
});
