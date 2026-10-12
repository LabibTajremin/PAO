import type Redis from 'ioredis';
import { v7 as uuid } from 'uuid';
import { startTestApi, type TestApi } from '../../../../../test/kit/api';
import { seedCatalog } from '../../../../../test/kit/catalog';
import { deliver, envelope, subscribedBus } from '../../../../../test/kit/events';
import { online, service } from '../../../../../test/kit/provider';
import { DATABASE, type Database } from '../../../../platform/db/database';
import { type DomainEvent } from '../../../../platform/events/domain-event';
import { REDIS } from '../../../../platform/redis/redis-client';
import { PROVIDER_SERVICE, type ProviderService } from '../../contract';

const electrician = service('electrician');

const event = (name: string, fields: Record<string, unknown>) =>
  ({ name, ...fields }) as unknown as DomainEvent;

const review = (subjectId: string, role: string, average: number, count: number) =>
  event('rating.ReviewSubmitted', {
    subjectId,
    subjectRole: role,
    newAverage: average,
    newCount: count,
  });

const cancelled = (providerId: string, by: string) =>
  event('booking.BookingCancelled', { bookingId: uuid(), providerId, by, afterAcceptance: true });

describe('provider read model and quality flags', () => {
  let api: TestApi;
  let db: Database;
  let providers: ProviderService;

  beforeEach(async () => {
    api = await startTestApi();
    await seedCatalog(api);
    db = api.app.get(DATABASE);
    providers = api.app.get(PROVIDER_SERVICE);
  });

  async function flagged(id: string) {
    const { rows } = await db.query<{ flagged_for_review: boolean; flag_reason: string }>(
      'SELECT flagged_for_review, flag_reason FROM provider.providers WHERE id = $1',
      [id],
    );
    return [rows[0]?.flagged_for_review, rows[0]?.flag_reason];
  }

  const who = (phone: string) => ({ phone, gender: 'male', level: 1 });

  it('flags providers and keeps the read model (TestEvents_QualityFlagsAndReadModel)', async () => {
    const rated = await online(api, who('01712345601'), electrician);
    await deliver(api, review(rated.id, 'customer', 1, 50));
    await deliver(api, review(rated.id, 'provider', 3, 9));
    expect(await flagged(rated.id)).toEqual([false, '']);
    await deliver(
      api,
      event('booking.BookingCompleted', { bookingId: uuid(), providerId: rated.id }),
    );
    await deliver(api, review(rated.id, 'provider', 3, 10));
    expect(await flagged(rated.id)).toEqual([true, 'rating_below_floor']);
    const canceller = await online(api, who('01712345602'), electrician);
    await deliver(api, cancelled(canceller.id, 'customer'));
    for (let i = 0; i < 4; i++) {
      await deliver(api, cancelled(canceller.id, 'provider'));
    }
    expect(await flagged(canceller.id)).toEqual([true, 'cancellations']);
    const complained = await online(api, who('01712345603'), electrician);
    const resolved = (verified: boolean) =>
      event('admin.ComplaintResolved', {
        complaintId: uuid(),
        ticketNumber: 'TCK-000001',
        againstId: complained.id,
        bookingId: uuid(),
        reporterId: uuid(),
        reporterRole: 'customer',
        verified,
        actorId: null,
      });
    await deliver(api, resolved(false));
    await deliver(api, resolved(true));
    expect(await flagged(complained.id)).toEqual([true, 'verified_complaint']);
    const status = (from: string, to: string) =>
      event('identity.AccountStatusChanged', {
        accountId: complained.id,
        from,
        to,
        reason: 'quality review',
        actorId: null,
        roles: ['provider'],
      });
    await deliver(api, status('active', 'suspended'));
    expect(await providers.isAvailable(complained.id)).toBe(false);
    const profile = await api.do('GET', '/v1/provider/profile', undefined, {
      token: complained.token,
    });
    expect(profile.body).toMatchObject({ status: 'suspended', flaggedForReview: true });
    await deliver(api, status('suspended', 'active'));
    await deliver(api, event('identity.AccountDeleted', { accountId: rated.id }));
    await deliver(api, event('identity.AccountDeleted', { accountId: uuid() }));
    await expect(providers.getProvider(rated.id)).rejects.toThrow();
    const { rows } = await db.query<{ n: string }>(
      `SELECT count(*) AS n FROM provider.outbox WHERE event_name = 'provider.ProviderFlaggedForReview'`,
    );
    expect(rows[0]?.n).toBe('3');
  });

  it('fails on broken payloads and lost stores (TestEvents_BrokenPayloadsAndFailures)', async () => {
    const bus = subscribedBus(api);
    const names = [
      'verification.ProviderLevelChanged',
      'identity.AccountStatusChanged',
      'identity.AccountDeleted',
      'rating.ReviewSubmitted',
      'booking.BookingCompleted',
      'booking.BookingCancelled',
      'admin.ComplaintResolved',
    ];
    for (const name of names) {
      const broken = { ...envelope(api, event(name, {})), payload: 'not json' as never };
      await expect(bus.dispatch(broken)).rejects.toThrow('payload is not an object');
    }
    const p = await online(api, who('01712345678'), electrician);
    await deliver(
      api,
      event('verification.ProviderLevelChanged', {
        providerId: p.id,
        from: 1,
        to: 0,
        reason: 'review',
      }),
    );
    expect(await providers.isAvailable(p.id)).toBe(false);
    await api.app.get<Redis>(REDIS).del(api.keys.key('cache', 'settings'));
    await db.query('ALTER TABLE admin.settings RENAME TO gone');
    for (const e of [review(p.id, 'provider', 2, 20), cancelled(p.id, 'provider')]) {
      await expect(bus.dispatch(envelope(api, e))).rejects.toThrow();
    }
    await db.query('ALTER TABLE admin.gone RENAME TO settings');
    await db.pool.end();
    for (const path of ['/v1/provider/enrolment', '/v1/provider/profile']) {
      expect((await api.do('GET', path, undefined, { token: p.token })).status).toBe(500);
    }
    const photo = { language: 'bn', photoMediaId: uuid() };
    expect((await api.do('PUT', '/v1/provider/profile', photo, { token: p.token })).status).toBe(
      500,
    );
    const deleted = envelope(api, event('identity.AccountDeleted', { accountId: p.id }));
    await expect(bus.dispatch(deleted)).rejects.toThrow();
  });
});
