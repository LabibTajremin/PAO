import { v7 as uuid } from 'uuid';
import { startTestApi, type TestApi } from '../../../../../test/kit/api';
import { seedCatalog } from '../../../../../test/kit/catalog';
import { deliver, envelope, subscribedBus } from '../../../../../test/kit/events';
import { signIn } from '../../../../../test/kit/identity';
import { enrolledProvider, service } from '../../../../../test/kit/provider';
import { standIn } from '../../../../../test/kit/stand-in';
import { DATABASE, type Database } from '../../../../platform/db/database';
import { DomainError } from '../../../../platform/errors/domain-error';
import { type DomainEvent } from '../../../../platform/events/domain-event';
import { HEALTH_ROUTES } from '../../../../platform/health/health';
import { checkRoutesAgainstSpec } from '../../../../platform/http/route-spec-check';
import { OPENAPI_DOCUMENT } from '../../../../platform/http/spec-routes';
import { PUSH_CAPTURE, type PushCapture } from '../../../../platform/testing/test-hooks';
import { BOOKING_SERVICE } from '../../../booking/contract/booking-service';
import { BookingErrors } from '../../../booking/contract/errors';
import { NOTIFICATION_SERVICE, type NotificationService } from '../../contract';

interface Who {
  readonly id: string;
  readonly token: string;
}

// Booking is not ported yet: a stand-in answers for the one booking these specs use.
const BOOKING_ID = uuid();
const bookings = {
  getBooking: (id: string) =>
    id === BOOKING_ID
      ? Promise.resolve({
          number: 'PAO-100001',
          serviceName: { en: 'Fan install', bn: 'ফ্যান লাগানো' },
          area: 'Gulshan',
          providerName: 'Rahim',
          customerName: 'Nusrat',
        })
      : Promise.reject(new DomainError(BookingErrors.NotFound)),
};

describe('notifications', () => {
  let api: TestApi;
  let customer: Who;
  let provider: Who;
  const event = (name: string, extra: object = {}) =>
    ({
      name,
      bookingId: BOOKING_ID,
      customerId: customer.id,
      providerId: provider.id,
      ...extra,
    }) as DomainEvent;
  const inbox = async (path: string, who: Who) => {
    const r = await api.do('GET', path, undefined, who);
    expect(r.status).toBe(200);
    return r.body as {
      items: { id: string; type: string; body: string }[];
      unreadCount: number;
      nextCursor?: string;
    };
  };

  beforeAll(async () => {
    api = await startTestApi({ imports: [standIn(new Map([[BOOKING_SERVICE, bookings]]))] });
    await seedCatalog(api);
    const tp = await signIn(api, '01812345651', 'customer');
    customer = { id: tp.account.id, token: tp.accessToken };
    provider = await enrolledProvider(api, '01712345651', 'male', service('electrician'));
    await api.do('PUT', '/v1/provider/profile', { language: 'en' }, provider);
  });

  it('serves its operations with the spec permissions', () => {
    const report = checkRoutesAgainstSpec(api.app, api.app.get(OPENAPI_DOCUMENT), HEALTH_ROUTES);
    expect(report.mismatched).toEqual([]);
    expect(report.undocumented).toEqual([]);
    const ours = /notifications|device-token/;
    expect(report.unserved.filter((op) => ours.test(op))).toEqual([]);
  });

  // TestNotifications_EveryBookingEvent, with booking details from the stand-in.
  it('puts every booking event in the right inbox', async () => {
    const device = { token: 'broken-provider-device', platform: 'android' };
    expect((await api.do('PUT', '/v1/provider/device-token', device, provider)).status).toBe(204);
    const cases: [DomainEvent, string, string][] = [
      [event('booking.BookingRequested'), '', 'booking_requested'],
      [event('booking.BookingRejected'), 'booking_rejected', ''],
      [event('booking.BookingTimedOut'), 'booking_timed_out', 'request_missed'],
      [event('booking.ExtraItemsProposed', { addedPaisa: 35000 }), 'extras_proposed', ''],
      [event('booking.ExtraItemsDecided', { approved: true }), '', 'extras_decided'],
      [event('booking.BookingCompleted'), 'booking_completed', 'booking_completed'],
      [event('booking.BookingCancelled', { by: 'customer' }), '', 'booking_cancelled'],
    ];
    for (const [e, toCustomer, toProvider] of cases) {
      await deliver(api, e);
      const sides: [string, string, Who][] = [
        [toCustomer, '/v1/customer/notifications?limit=1', customer],
        [toProvider, '/v1/provider/notifications?limit=1', provider],
      ];
      for (const [want, path, who] of sides.filter(([w]) => w !== '')) {
        expect((await inbox(path, who)).items[0]?.type).toBe(want);
      }
    }
    const prov = await inbox('/v1/provider/notifications?limit=1', provider);
    expect(prov.items[0]?.body).toBe('Booking PAO-100001 was cancelled.');
    const bus = subscribedBus(api);
    for (const name of [
      'booking.BookingAccepted',
      'verification.DocumentExpired',
      'identity.AccountDeleted',
    ]) {
      const broken = { ...envelope(api, { name }), payload: 'nope' as unknown as DomainEvent };
      await expect(bus.dispatch(broken)).rejects.toThrow();
    }
    const before = (await inbox('/v1/provider/notifications', provider)).items.length;
    await deliver(api, { ...event('booking.BookingAccepted'), bookingId: uuid() } as DomainEvent);
    expect((await inbox('/v1/provider/notifications', provider)).items).toHaveLength(before);
  });

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

  // TestNotifications_BookingEventsReachBothSides, the inbox, device and deletion parts.
  it('pushes once, drops dead devices, keeps read state and forgets deleted accounts', async () => {
    const capture = api.app.get<PushCapture>(PUSH_CAPTURE, { strict: false });
    for (const token of ['customer-device-token-1', 'invalid-customer-device']) {
      await api.do('PUT', '/v1/customer/device-token', { token, platform: 'android' }, customer);
    }
    const accepted = event('booking.BookingAccepted');
    const bus = subscribedBus(api);
    const env = envelope(api, accepted);
    await bus.dispatch(env);
    await bus.dispatch(env);
    expect(capture.sentTo('customer-device-token-1')).toEqual([
      expect.objectContaining({ data: { type: 'booking_accepted', bookingId: BOOKING_ID } }),
    ]);
    const db = api.app.get<Database>(DATABASE);
    const dead = await db.pool.query(
      "SELECT 1 FROM notification.device_tokens WHERE token LIKE 'invalid-%'",
    );
    expect(dead.rowCount).toBe(0);

    const all = await inbox('/v1/customer/notifications', customer);
    expect(all.unreadCount).toBe(all.items.length);
    const page = await inbox('/v1/customer/notifications?limit=2', customer);
    const next = await inbox(
      `/v1/customer/notifications?limit=2&cursor=${page.nextCursor ?? ''}`,
      customer,
    );
    expect([...page.items, ...next.items].slice(0, 3)).toEqual(all.items.slice(0, 3));
    const bad = await api.do('GET', '/v1/provider/notifications?cursor=%25', undefined, provider);
    expect(bad.status).toBe(422);

    const id = all.items[0]?.id ?? '';
    expect(
      (await api.do('POST', `/v1/provider/notifications/${id}/read`, undefined, provider)).status,
    ).toBe(404);
    expect(
      (await api.do('POST', `/v1/customer/notifications/${id}/read`, undefined, customer)).status,
    ).toBe(204);
    expect((await inbox('/v1/customer/notifications', customer)).unreadCount).toBe(
      all.unreadCount - 1,
    );
    for (const [path, who] of [
      ['/v1/customer/notifications/read-all', customer],
      ['/v1/provider/notifications/read-all', provider],
    ] as const) {
      expect((await api.do('POST', path, undefined, who)).status).toBe(204);
    }
    expect((await inbox('/v1/provider/notifications', provider)).unreadCount).toBe(0);
    await deliver(api, { name: 'identity.AccountDeleted', accountId: customer.id } as DomainEvent);
    expect((await inbox('/v1/customer/notifications', customer)).items).toEqual([]);
  });

  // TestNotifications_VerificationEvents.
  it('tells providers about verification and fails without the database', async () => {
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
    await deliver(api, {
      name: 'verification.DocumentRejected',
      providerId: provider.id,
      item: 'selfie',
      reason: 'Blurred',
    } as DomainEvent);
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
    await expect(
      deliver(api, { name: 'verification.DocumentExpired', providerId: p.id } as DomainEvent),
    ).rejects.toThrow();
  });
});
