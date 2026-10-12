import { v7 as uuid } from 'uuid';
import { startTestApi, type TestApi } from '../../../../../test/kit/api';
import { deliver, envelope, subscribedBus } from '../../../../../test/kit/events';
import { HEALTH_ROUTES } from '../../../../platform/health/health';
import { checkRoutesAgainstSpec } from '../../../../platform/http/route-spec-check';
import { OPENAPI_DOCUMENT } from '../../../../platform/http/spec-routes';
import { type DomainEvent } from '../../../../platform/events/domain-event';
import { dhakaDate } from '../../app/read-dashboard';
import { addDays } from '../../domain/dashboard';
import { DASHBOARD_REPOSITORY, type DashboardRepository } from '../../port/dashboard-repository';

const event = (name: string, fields: Record<string, unknown>) =>
  ({ name, ...fields }) as DomainEvent;

describe('admin dashboard read model', () => {
  let api: TestApi;

  beforeAll(async () => {
    api = await startTestApi();
  });

  it('serves every admin operation with the spec permission', () => {
    const report = checkRoutesAgainstSpec(api.app, api.app.get(OPENAPI_DOCUMENT), HEALTH_ROUTES);
    expect(report.mismatched).toEqual([]);
    expect(report.undocumented).toEqual([]);
    const ours = /\/v1\/admin\/(settings|complaints|dashboard|providers|customers)|\/reports$/;
    expect(report.unserved.filter((op) => ours.test(op))).toEqual([]);
  });

  it('counts providers and bookings from events, once per event', async () => {
    const [active, pending, suspended, gone] = [uuid(), uuid(), uuid(), uuid()];
    for (const id of [active, pending, suspended, gone]) {
      await deliver(api, event('identity.AccountCreated', { accountId: id, role: 'provider' }));
    }
    await deliver(api, event('identity.AccountCreated', { accountId: uuid(), role: 'customer' }));
    for (const id of [active, suspended]) {
      await deliver(
        api,
        event('verification.ProviderLevelChanged', { providerId: id, from: 0, to: 1, reason: '' }),
      );
    }
    const suspend = {
      accountId: suspended,
      from: 'active',
      to: 'suspended',
      reason: 'test',
      actorId: null,
      roles: ['provider'],
    };
    await deliver(api, event('identity.AccountStatusChanged', suspend));
    const customerOnly = {
      accountId: uuid(),
      from: 'active',
      to: 'banned',
      reason: 'test',
      actorId: null,
      roles: ['customer'],
    };
    await deliver(api, event('identity.AccountStatusChanged', customerOnly));
    await deliver(api, event('identity.AccountDeleted', { accountId: gone }));
    const bus = subscribedBus(api);
    const requested = envelope(api, event('booking.BookingRequested', {}));
    await bus.dispatch(requested);
    await bus.dispatch(requested);
    await deliver(api, event('booking.BookingRequested', {}), bus);
    await deliver(api, event('booking.BookingCompleted', {}), bus);
    await expect(
      bus.dispatch(envelope(api, event('identity.AccountCreated', { role: 'provider' }))),
    ).rejects.toThrow('accountId is missing');

    const today = dhakaDate(api.clock.now());
    const repo = api.app.get<DashboardRepository>(DASHBOARD_REPOSITORY, { strict: false });
    const d = await repo.dashboard(addDays(today, -29));
    expect(d.providersByStatus).toEqual({ active: 1, pending: 1, suspended: 1 });
    expect(d.providersByLevel).toEqual({ '0': 1, '1': 2 });
    expect(d.days).toEqual([{ date: today, total: 2, completed: 1 }]);
    expect(d.openComplaints).toBe(0);
    expect((await repo.dashboard(addDays(today, 1))).days).toEqual([]);
  });
});
