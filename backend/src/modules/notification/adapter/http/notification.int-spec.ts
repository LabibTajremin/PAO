import { v7 as uuid } from 'uuid';
import { startTestApi, type TestApi } from '../../../../../test/kit/api';
import { type Job, requestedJob } from '../../../../../test/kit/booking';
import { seedCatalog } from '../../../../../test/kit/catalog';
import { deliver, envelope, relayEvents, subscribedBus } from '../../../../../test/kit/events';
import { signIn } from '../../../../../test/kit/identity';
import { enrolledProvider, service } from '../../../../../test/kit/provider';
import { DATABASE, type Database } from '../../../../platform/db/database';
import { type DomainEvent } from '../../../../platform/events/domain-event';
import { HEALTH_ROUTES } from '../../../../platform/health/health';
import { checkRoutesAgainstSpec } from '../../../../platform/http/route-spec-check';
import { OPENAPI_DOCUMENT } from '../../../../platform/http/spec-routes';
import { PUSH_CAPTURE, type PushCapture } from '../../../../platform/testing/test-hooks';
import { NOTIFICATION_SERVICE, type NotificationService } from '../../contract';

interface Who {
  readonly id: string;
  readonly token: string;
}

interface Inbox {
  items: { id: string; type: string; title: string; body: string }[];
  unreadCount: number;
  nextCursor?: string;
}

describe('notifications', () => {
  let api: TestApi;

  const inbox = async (path: string, who: Who): Promise<Inbox> => {
    const r = await api.do('GET', path, undefined, who);
    expect(r.status).toBe(200);
    return r.body as unknown as Inbox;
  };
  const types = (page: Inbox) => page.items.map((i) => i.type);

  beforeEach(async () => {
    api = await startTestApi();
  });

  it('serves its operations with the spec permissions', () => {
    const report = checkRoutesAgainstSpec(api.app, api.app.get(OPENAPI_DOCUMENT), HEALTH_ROUTES);
    expect(report.mismatched).toEqual([]);
    expect(report.undocumented).toEqual([]);
    const ours = /notifications|device-token/;
    expect(report.unserved.filter((op) => ours.test(op))).toEqual([]);
  });

  it('puts every booking event in the right inbox (TestNotifications_EveryBookingEvent)', async () => {
    const j = await requestedJob(api, '01712345651', '01812345651');
    await api.do('PUT', '/v1/provider/profile', { language: 'en' }, j.provider);
    const device = { token: 'broken-provider-device', platform: 'android' };
    expect((await api.do('PUT', '/v1/provider/device-token', device, j.provider)).status).toBe(204);
    const parties = { bookingId: j.id, customerId: j.customer.id, providerId: j.provider.id };
    const event = (name: string, extra: object = {}) =>
      ({ name: `booking.${name}`, ...parties, ...extra }) as DomainEvent;
    const cases: [DomainEvent, string, string][] = [
      [event('BookingRejected'), 'booking_rejected', ''],
      [event('BookingTimedOut'), 'booking_timed_out', 'request_missed'],
      [event('ProviderOnTheWay'), 'provider_on_the_way', ''],
      [event('ProviderArrived'), 'provider_arrived', ''],
      [event('BookingStarted'), 'booking_started', ''],
      [event('ExtraItemsProposed', { addedPaisa: 35000 }), 'extras_proposed', ''],
      [event('ExtraItemsDecided', { approved: true }), '', 'extras_decided'],
      [event('ExtraItemsDecided', { approved: false }), '', 'extras_decided'],
      [event('BookingCompleted'), 'booking_completed', 'booking_completed'],
      [event('BookingCancelled', { by: 'customer' }), '', 'booking_cancelled'],
      [event('BookingCancelled', { by: 'provider' }), 'booking_cancelled', ''],
    ];
    for (const [e, toCustomer, toProvider] of cases) {
      await deliver(api, e);
      const sides: [string, string, Who][] = [
        [toCustomer, '/v1/customer/notifications?limit=1', j.customer],
        [toProvider, '/v1/provider/notifications?limit=1', j.provider],
      ];
      for (const [want, path, who] of sides.filter(([w]) => w !== '')) {
        expect(`${e.name} ${String(types(await inbox(path, who))[0])}`).toBe(`${e.name} ${want}`);
      }
    }
    const number = (await api.do('GET', `/v1/provider/jobs/${j.id}`, undefined, j.provider)).body
      ?.number as string;
    const prov = await inbox('/v1/provider/notifications?limit=1', j.provider);
    expect(prov.items[0]?.body).toBe(`Booking ${number} was cancelled.`);
    await brokenAndUnknown(j);
  });

  async function brokenAndUnknown(j: Job) {
    const bus = subscribedBus(api);
    for (const name of [
      'booking.BookingAccepted',
      'verification.DocumentExpired',
      'identity.AccountDeleted',
    ]) {
      const broken = { ...envelope(api, { name }), payload: 'nope' as unknown as DomainEvent };
      await expect(bus.dispatch(broken)).rejects.toThrow();
    }
    const before = (await inbox('/v1/provider/notifications', j.provider)).items.length;
    const unknown = {
      name: 'booking.BookingAccepted',
      bookingId: uuid(),
      providerId: j.provider.id,
    };
    await deliver(api, unknown);
    expect((await inbox('/v1/provider/notifications', j.provider)).items).toHaveLength(before);
  }

  it('sends through the contract and refuses an unknown template', async () => {
    const notifications = api.app.get<NotificationService>(NOTIFICATION_SERVICE, { strict: false });
    const m = {
      recipientId: uuid(),
      app: 'customer',
      language: 'bn' as const,
      template: 'complaint_resolved',
      data: { ticket: '1001' },
      bookingId: null,
      channels: [],
      dedupeKey: 'k1',
    };
    await notifications.send(m);
    await expect(notifications.send({ ...m, template: 'nope', dedupeKey: 'k2' })).rejects.toThrow();
  });

  it('reaches both sides through the booking API (TestNotifications_BookingEventsReachBothSides)', async () => {
    const j = await requestedJob(api, '01712345631', '01812345631');
    const capture = api.app.get<PushCapture>(PUSH_CAPTURE, { strict: false });
    const devices: [string, string, string, Who][] = [
      ['provider', 'provider-device-token-1', 'android', j.provider],
      ['provider', 'invalid-provider-device', 'ios', j.provider],
      ['customer', 'customer-device-token-1', 'android', j.customer],
    ];
    for (const [side, token, platform, who] of devices) {
      expect(
        (await api.do('PUT', `/v1/${side}/device-token`, { token, platform }, who)).status,
      ).toBe(204);
    }
    await relayEvents(api);
    expect(capture.sentTo('provider-device-token-1')).toEqual([
      expect.objectContaining({ data: { type: 'booking_requested', bookingId: j.id } }),
    ]);
    const db = api.app.get<Database>(DATABASE);
    const dead = await db.query(
      "SELECT 1 FROM notification.device_tokens WHERE token LIKE 'invalid-%'",
    );
    expect(dead.rowCount).toBe(0);
    const path = `/v1/provider/jobs/${j.id}`;
    await api.do('POST', `${path}/accept`, undefined, j.provider);
    await api.do('POST', `${path}/on-the-way`, undefined, j.provider);
    await api.do('POST', `${path}/cancel`, { reason: 'emergency' }, j.provider);
    await relayEvents(api);
    await db.query('UPDATE booking.outbox SET published_at = NULL');
    await relayEvents(api);
    const cust = await inbox('/v1/customer/notifications', j.customer);
    expect(types(cust)).toEqual(['booking_cancelled', 'provider_on_the_way', 'booking_accepted']);
    expect(cust.unreadCount).toBe(3);
    expect(cust.items[2]?.title).toBe('Booking accepted');
    expect(capture.sentTo('customer-device-token-1')).toHaveLength(3);
    await readState(j, cust);
  });

  async function readState(j: Job, cust: Inbox) {
    const page = await inbox('/v1/customer/notifications?limit=2', j.customer);
    const next = await inbox(
      `/v1/customer/notifications?limit=2&cursor=${page.nextCursor ?? ''}`,
      j.customer,
    );
    expect(next.items).toHaveLength(1);
    const bad = await api.do('GET', '/v1/provider/notifications?cursor=%25', undefined, j.provider);
    expect(bad.status).toBe(422);
    const id = cust.items[0]?.id ?? '';
    expect(
      (await api.do('POST', `/v1/provider/notifications/${id}/read`, undefined, j.provider)).status,
    ).toBe(404);
    expect(
      (await api.do('POST', `/v1/customer/notifications/${id}/read`, undefined, j.customer)).status,
    ).toBe(204);
    expect((await inbox('/v1/customer/notifications', j.customer)).unreadCount).toBe(2);
    for (const [p, who] of [
      ['/v1/customer/notifications/read-all', j.customer],
      ['/v1/provider/notifications/read-all', j.provider],
    ] as const) {
      expect((await api.do('POST', p, undefined, who)).status).toBe(204);
    }
    const prov = await inbox('/v1/provider/notifications', j.provider);
    expect(prov.unreadCount).toBe(0);
    expect(types(prov)).toContain('booking_requested');
    const pid = prov.items[0]?.id ?? '';
    expect(
      (await api.do('POST', `/v1/provider/notifications/${pid}/read`, undefined, j.provider))
        .status,
    ).toBe(204);
    await deliver(api, {
      name: 'identity.AccountDeleted',
      accountId: j.customer.id,
    } as DomainEvent);
    expect((await inbox('/v1/customer/notifications', j.customer)).items).toEqual([]);
  }

  // TestNotifications_VerificationEvents.
  it('tells providers about verification and fails without the database', async () => {
    await seedCatalog(api);
    const provider = await enrolledProvider(api, '01712345651', 'male', service('electrician'));
    await api.do('PUT', '/v1/provider/profile', { language: 'en' }, provider);
    const tp = await signIn(api, '01712345641', 'partner');
    const p = { id: tp.account.id, token: tp.accessToken };
    const events = [
      { name: 'verification.ProviderLevelChanged', from: 0, to: 1, reason: 'approved' },
      { name: 'verification.DocumentRejected', item: 'selfie', reason: 'Blurred' },
      { name: 'verification.DocumentExpired', item: 'police_clearance' },
      { name: 'verification.DocumentExpiring', item: 'police_clearance', daysLeft: 7 },
      {
        name: 'verification.Level2SessionScheduled',
        scheduledAt: '2026-10-12T10:00:00Z',
        location: 'Gulshan',
      },
    ];
    for (const e of events) {
      await deliver(api, { ...e, providerId: p.id } as unknown as DomainEvent);
    }
    expect((await inbox('/v1/provider/notifications', p)).items).toHaveLength(5);
    const rejected = {
      name: 'verification.DocumentRejected',
      providerId: provider.id,
      item: 'selfie',
      reason: 'Blurred',
    };
    await deliver(api, rejected);
    expect((await inbox('/v1/provider/notifications?limit=1', provider)).items[0]?.body).toContain(
      'selfie',
    );
    const both = { token: await api.token(p.id, ['provider', 'customer']) };
    const device = { token: 'device-token-closed', platform: 'web' };
    const calls = [
      ['GET', '/v1/provider/notifications'],
      ['GET', '/v1/customer/notifications'],
      ['POST', '/v1/customer/notifications/read-all'],
      ['POST', '/v1/provider/notifications/read-all'],
      ['POST', `/v1/customer/notifications/${uuid()}/read`],
      ['PUT', '/v1/customer/device-token'],
      ['PUT', '/v1/provider/device-token'],
    ] as const;
    await api.app.get<Database>(DATABASE).close();
    for (const [method, path] of calls) {
      expect((await api.do(method, path, method === 'PUT' ? device : undefined, both)).status).toBe(
        500,
      );
    }
    const expired = { name: 'verification.DocumentExpired', providerId: p.id };
    await expect(deliver(api, expired as DomainEvent)).rejects.toThrow();
  });
});
