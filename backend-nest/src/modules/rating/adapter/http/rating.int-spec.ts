import { randomUUID } from 'node:crypto';
import { v7 as uuid } from 'uuid';
import { startTestApi, type TestApi } from '../../../../../test/kit/api';
import { completedJob, customer, requestedJob } from '../../../../../test/kit/booking';
import { deliver, relayEvents } from '../../../../../test/kit/events';
import { upload } from '../../../../../test/kit/media';
import { enrolledProvider, service } from '../../../../../test/kit/provider';
import { DATABASE, type Database } from '../../../../platform/db/database';
import { HEALTH_ROUTES } from '../../../../platform/health/health';
import { checkRoutesAgainstSpec } from '../../../../platform/http/route-spec-check';
import { OPENAPI_DOCUMENT } from '../../../../platform/http/spec-routes';
import { seedId } from '../../../catalog/app/seed-catalog';
import { BookingEvents } from '../../../booking/contract/events';
import { RATING_SERVICE, type RatingService } from '../../contract';

interface Party {
  readonly id: string;
  readonly token: string;
}

/** Books `provider` for `client`, runs the job to completion and relays its events. */
async function completeFor(api: TestApi, provider: Party, client: Party, address: string) {
  const body = {
    providerId: provider.id,
    serviceId: service('electrician'),
    timing: 'asap',
    addressId: address,
    items: [{ subServiceId: seedId('sub-service', 'fan-install'), quantity: 1 }],
  };
  const headers = { 'Idempotency-Key': randomUUID() };
  const booked = await api.do('POST', '/v1/customer/bookings', body, {
    token: client.token,
    headers,
  });
  const id = booked.body?.id as string;
  const path = `/v1/provider/jobs/${id}`;
  const p = { token: provider.token };
  await api.do('POST', `${path}/accept`, undefined, p);
  const code = await api.do('GET', `/v1/customer/bookings/${id}/start-code`, undefined, client);
  await api.do('POST', `${path}/on-the-way`, undefined, p);
  await api.do('POST', `${path}/arrived`, undefined, p);
  await api.do('POST', `${path}/start`, { code: code.body?.code }, p);
  await api.do('POST', `${path}/complete`, { cashReceived: true }, p);
  await relayEvents(api);
  return id;
}

describe('rating', () => {
  let api: TestApi;
  let ratings: RatingService;

  beforeEach(async () => {
    api = await startTestApi();
    ratings = api.app.get(RATING_SERVICE, { strict: false });
  });

  it('serves its operations with the spec permissions', () => {
    const report = checkRoutesAgainstSpec(api.app, api.app.get(OPENAPI_DOCUMENT), HEALTH_ROUTES);
    expect(report.mismatched).toEqual([]);
    expect(report.undocumented).toEqual([]);
    const ours = /\/(review|reviews|rating)$/;
    expect(report.unserved.filter((op) => ours.test(op))).toEqual([]);
  });

  it('takes one review per side after completion (TestRating_BothSidesOnceAfterCompletion)', async () => {
    const open = await requestedJob(api, '01712345611', '01812345611');
    const early = await api.do(
      'POST',
      `/v1/customer/bookings/${open.id}/review`,
      { stars: 5 },
      open.customer,
    );
    expect(early.code).toBe('REVIEW_NOT_ALLOWED');
    const j = await completedJob(api, '01712345612', '01812345612');
    const review = { stars: 4, tags: ['on_time', 'clean'], comment: 'Quick and tidy' };
    const path = `/v1/customer/bookings/${j.id}/review`;
    const first = await api.do('POST', path, review, j.customer);
    expect(first.status).toBe(201);
    expect(first.body).toMatchObject({
      authorName: 'Nusrat',
      serviceName: { en: expect.any(String) as unknown },
    });
    expect((await api.do('POST', path, review, j.customer)).code).toBe('REVIEW_ALREADY_SUBMITTED');
    const back = { stars: 5, tags: ['polite', 'paid_promptly'] };
    const jobPath = `/v1/provider/jobs/${j.id}/review`;
    const second = await api.do('POST', jobPath, back, j.provider);
    expect(second.status).toBe(201);
    expect(second.body).not.toHaveProperty('comment');
    expect((await api.do('POST', jobPath, back, open.provider)).code).toBe('REVIEW_NOT_ALLOWED');
    await relayEvents(api);
    const mine = await api.do('GET', '/v1/provider/rating', undefined, j.provider);
    expect(mine.body).toEqual({
      average: 4,
      count: 1,
      distribution: { '1': 0, '2': 0, '3': 0, '4': 1, '5': 0 },
    });
    expect(
      (await api.do('GET', '/v1/provider/reviews', undefined, j.provider)).body?.items,
    ).toHaveLength(1);
    const pub = await api.do(
      'GET',
      `/v1/customer/providers/${j.provider.id}`,
      undefined,
      j.customer,
    );
    expect(pub.body).toMatchObject({ completedJobs: 1, rating: { count: 1 } });
    expect(
      (await api.do('GET', `/v1/customer/providers/${uuid()}`, undefined, j.customer)).status,
    ).toBe(404);
    expect(await ratings.getCustomerRating(j.customer.id)).toMatchObject({ average: 5, count: 1 });
    const all = await ratings.getProviderRatings([j.provider.id, uuid()]);
    expect([...all.keys()]).toEqual([j.provider.id]);
    expect(all.get(j.provider.id)?.distribution[3]).toBe(1);
    expect((await ratings.getProviderRating(uuid())).count).toBe(0);
    expect(await ratings.hasReviewed(j.id, j.customer.id)).toBe(true);
  });

  it('shows on booking views who reviewed (TestRating_BookingViewsShowWhoReviewed)', async () => {
    const open = await requestedJob(api, '01712345621', '01812345621');
    const j = await completedJob(api, '01712345622', '01812345622');
    const reviewed = async (path: string, who: Party) => {
      const r = await api.do('GET', path, undefined, who);
      expect(r.status).toBe(200);
      return r.body?.reviewedByMe;
    };
    const customerView = `/v1/customer/bookings/${j.id}`;
    const providerView = `/v1/provider/jobs/${j.id}`;
    expect(await reviewed(`/v1/customer/bookings/${open.id}`, open.customer)).toBe(false);
    expect(await reviewed(customerView, j.customer)).toBe(false);
    await api.do('POST', `${customerView}/review`, { stars: 5 }, j.customer);
    expect(await reviewed(customerView, j.customer)).toBe(true);
    expect(await reviewed(providerView, j.provider)).toBe(false);
    await api.do('POST', `${providerView}/review`, { stars: 4 }, j.provider);
    expect(await reviewed(providerView, j.provider)).toBe(true);
    await api.app
      .get<Database>(DATABASE)
      .query('ALTER TABLE rating.reviews RENAME TO reviews_gone');
    expect((await api.do('GET', customerView, undefined, j.customer)).status).toBe(500);
  });

  it('opens a booking once when the event comes again', async () => {
    const j = await completedJob(api, '01712345631', '01812345631');
    const again = { bookingId: j.id, customerName: 'Someone Else' };
    await deliver(api, { name: BookingEvents.BookingCompleted, ...again });
    const rows = await api.app
      .get<Database>(DATABASE)
      .query('SELECT customer_name FROM rating.reviewable_bookings WHERE booking_id = $1', [j.id]);
    expect(rows.rows).toEqual([{ customer_name: 'Nusrat Jahan' }]);
  });

  it('pages reviews, shows the photo and fails without the database (TestRating_ListsProfilePhotoAndFailures)', async () => {
    const j = await completedJob(api, '01712345621', '01812345621');
    const p = j.provider;
    const { customer: second, addressId } = await customer(api, '01812345622');
    const id = await completeFor(api, p, second, addressId);
    for (const [booking, who] of [
      [j.id, j.customer],
      [id, second],
    ] as const) {
      const r = await api.do('POST', `/v1/customer/bookings/${booking}/review`, { stars: 5 }, who);
      expect(r.status).toBe(201);
    }
    const list = `/v1/customer/providers/${p.id}/reviews?limit=1`;
    const page = await api.do('GET', list, undefined, second);
    expect(page.body?.items).toHaveLength(1);
    const next = await api.do(
      'GET',
      `${list}&cursor=${page.body?.nextCursor as string}`,
      undefined,
      second,
    );
    expect(next.body?.items).toHaveLength(1);
    expect(next.body).not.toHaveProperty('nextCursor');
    const photo = await upload(api, p.id, 'provider', 'avatar');
    await api.do('PUT', '/v1/provider/profile', { language: 'bn', photoMediaId: photo }, p);
    const pub = await api.do('GET', `/v1/customer/providers/${p.id}`, undefined, second);
    expect(pub.body?.photoUrl).toBeDefined();
    const pending = await enrolledProvider(api, '01712345623', 'male', service('electrician'));
    expect(
      (await api.do('GET', `/v1/customer/providers/${pending.id}`, undefined, second)).status,
    ).toBe(404);
    expect((await api.do('GET', `${list}&cursor=%25`, undefined, second)).status).toBe(422);
    await api.app.get<Database>(DATABASE).close();
    const failing = [
      ['/v1/provider/rating', p],
      ['/v1/provider/reviews', p],
      [`/v1/customer/providers/${p.id}/reviews`, second],
    ] as const;
    for (const [path, who] of failing) {
      expect((await api.do('GET', path, undefined, who)).status).toBe(500);
    }
  });
});
