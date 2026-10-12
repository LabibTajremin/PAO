import { v7 as uuid } from 'uuid';
import { startTestApi, type TestApi } from '../../../../../test/kit/api';
import { deliver, relayEvents } from '../../../../../test/kit/events';
import { standIn } from '../../../../../test/kit/stand-in';
import { DATABASE, type Database } from '../../../../platform/db/database';
import { DomainError } from '../../../../platform/errors/domain-error';
import { HEALTH_ROUTES } from '../../../../platform/health/health';
import { checkRoutesAgainstSpec } from '../../../../platform/http/route-spec-check';
import { OPENAPI_DOCUMENT } from '../../../../platform/http/spec-routes';
import { BOOKING_SERVICE } from '../../../booking/contract/booking-service';
import { BookingErrors } from '../../../booking/contract/errors';
import { BookingEvents, type BookingCompleted } from '../../../booking/contract/events';
import { RATING_SERVICE, type RatingService } from '../../contract';

interface Party {
  readonly id: string;
  readonly token: string;
}

// The Go specs reach completed bookings through the booking API; until booking is
// ported, a delivered BookingCompleted event opens the booking for review.
async function completed(api: TestApi, customer: Party, provider: Party): Promise<string> {
  const bookingId = uuid();
  const event: BookingCompleted = {
    name: BookingEvents.BookingCompleted,
    bookingId,
    number: 'PAO-1',
    customerId: customer.id,
    providerId: provider.id,
    serviceId: uuid(),
    at: api.clock.now().toISOString(),
    totalPaisa: 50000,
    customerName: 'Nusrat Jahan',
    providerName: 'Rahim Uddin',
    serviceName: { en: 'Fan install', bn: 'ফ্যান লাগানো' },
  };
  await deliver(api, event);
  return bookingId;
}

describe('rating', () => {
  let api: TestApi;
  let ratings: RatingService;
  const party = async (role: string): Promise<Party> => {
    const id = uuid();
    return { id, token: await api.token(id, [role]) };
  };

  beforeAll(async () => {
    // Until booking is ported, notification finds none of these bookings and skips them.
    const bookings = { getBooking: () => Promise.reject(new DomainError(BookingErrors.NotFound)) };
    api = await startTestApi({ imports: [standIn(new Map([[BOOKING_SERVICE, bookings]]))] });
    ratings = api.app.get(RATING_SERVICE, { strict: false });
  });

  it('serves its operations with the spec permissions', () => {
    const report = checkRoutesAgainstSpec(api.app, api.app.get(OPENAPI_DOCUMENT), HEALTH_ROUTES);
    expect(report.mismatched).toEqual([]);
    expect(report.undocumented).toEqual([]);
    const ours = /\/(review|reviews|rating)$/;
    expect(report.unserved.filter((op) => ours.test(op))).toEqual([]);
  });

  // TestRating_BothSidesOnceAfterCompletion, without the public profile (provider's).
  it('takes one review per side after completion', async () => {
    const [customer, provider, stranger] = [
      await party('customer'),
      await party('provider'),
      await party('provider'),
    ];
    const early = await api.do(
      'POST',
      `/v1/customer/bookings/${uuid()}/review`,
      { stars: 5 },
      customer,
    );
    expect(early.code).toBe('REVIEW_NOT_ALLOWED');
    const id = await completed(api, customer, provider);
    const review = { stars: 4, tags: ['on_time', 'clean'], comment: 'Quick and tidy' };
    const path = `/v1/customer/bookings/${id}/review`;
    const first = await api.do('POST', path, review, customer);
    expect(first.status).toBe(201);
    expect(first.body).toMatchObject({ authorName: 'Nusrat', serviceName: { en: 'Fan install' } });
    expect((await api.do('POST', path, review, customer)).code).toBe('REVIEW_ALREADY_SUBMITTED');
    const back = { stars: 5, tags: ['polite', 'paid_promptly'] };
    const jobPath = `/v1/provider/jobs/${id}/review`;
    const second = await api.do('POST', jobPath, back, provider);
    expect(second.status).toBe(201);
    expect(second.body).not.toHaveProperty('comment');
    expect((await api.do('POST', jobPath, back, stranger)).code).toBe('REVIEW_NOT_ALLOWED');
    await relayEvents(api);

    const mine = await api.do('GET', '/v1/provider/rating', undefined, provider);
    expect(mine.body).toEqual({
      average: 4,
      count: 1,
      distribution: { '1': 0, '2': 0, '3': 0, '4': 1, '5': 0 },
    });
    const list = await api.do('GET', '/v1/provider/reviews', undefined, provider);
    expect(list.body?.items).toHaveLength(1);
    expect(await ratings.getCustomerRating(customer.id)).toMatchObject({ average: 5, count: 1 });
    const all = await ratings.getProviderRatings([provider.id, uuid()]);
    expect([...all.keys()]).toEqual([provider.id]);
    expect(all.get(provider.id)?.distribution[3]).toBe(1);
    expect((await ratings.getProviderRating(uuid())).count).toBe(0);
    expect(await ratings.hasReviewed(id, customer.id)).toBe(true);
    expect(await ratings.hasReviewed(id, stranger.id)).toBe(false);
  });

  it('opens a booking once when the event comes again', async () => {
    const [customer, provider] = [await party('customer'), await party('provider')];
    const id = await completed(api, customer, provider);
    const db = api.app.get<Database>(DATABASE);
    const again = { bookingId: id, customerName: 'Someone Else' };
    await deliver(api, { name: BookingEvents.BookingCompleted, ...again });
    const rows = await db.pool.query(
      'SELECT customer_name FROM rating.reviewable_bookings WHERE booking_id = $1',
      [id],
    );
    expect(rows.rows).toEqual([{ customer_name: 'Nusrat Jahan' }]);
  });

  // TestRating_ListsProfilePhotoAndFailures, the list and failure parts.
  it('pages a provider’s reviews and fails without the database', async () => {
    const provider = await party('provider');
    const [first, second] = [await party('customer'), await party('customer')];
    for (const customer of [first, second]) {
      const id = await completed(api, customer, provider);
      const r = await api.do('POST', `/v1/customer/bookings/${id}/review`, { stars: 5 }, customer);
      expect(r.status).toBe(201);
      api.clock.advance(1000);
    }
    const list = `/v1/customer/providers/${provider.id}/reviews?limit=1`;
    const page = await api.do('GET', list, undefined, second);
    expect(page.body?.items).toHaveLength(1);
    const cursor = page.body?.nextCursor as string;
    const next = await api.do('GET', `${list}&cursor=${cursor}`, undefined, second);
    expect(next.body?.items).toHaveLength(1);
    expect(next.body).not.toHaveProperty('nextCursor');
    expect((await api.do('GET', `${list}&cursor=%25`, undefined, second)).status).toBe(422);

    const db = api.app.get<Database>(DATABASE);
    const third = await party('customer');
    const id = await completed(api, third, provider);
    await db.pool.query('ALTER TABLE rating.aggregates RENAME TO aggregates_gone');
    const lost = await api.do('POST', `/v1/customer/bookings/${id}/review`, { stars: 3 }, third);
    expect(lost.status).toBe(500);
    await db.close();
    const failing = [
      ['/v1/provider/rating', provider],
      ['/v1/provider/reviews', provider],
      [`/v1/customer/providers/${provider.id}/reviews`, second],
    ] as const;
    for (const [path, who] of failing) {
      expect((await api.do('GET', path, undefined, who)).status).toBe(500);
    }
  });
});
