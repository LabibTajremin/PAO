import { customerAt, phoneFor } from './support/actors';
import {
  bookASAP,
  customerStatus,
  job,
  lines,
  mustJob,
  onlineProvider,
  pushed,
  startCode,
  type Line,
  type Order,
  type Partner,
} from './support/booking';
import { eventually, get, send, type Session } from './support/client';
import { list, obj, str } from './support/json';
import { catalogService, nearby, type Sub } from './support/provider';

// A booking between a customer and a provider.
interface Booked {
  readonly c: Session;
  readonly p: Partner;
  readonly id: string;
}

// Books two of `fan` with the provider, checks the provider was paged and that contact
// details are shared only after acceptance; returns the booking ID.
async function requestAndAccept(order: Order, p: Partner, fan: Sub): Promise<string> {
  const c = order.customer;
  const b = await bookASAP(order, { sub: fan, quantity: 2 });
  const id = str(b.id);
  expect(b).toMatchObject({ total: 2 * fan.price, timing: 'asap' });
  await eventually(10_000, 'request pushed to the provider', () =>
    pushed(p.pushToken, 'booking_requested', id),
  );
  const request = (await get(`/v1/provider/jobs/${id}`, p.session)).expect(200);
  expect(obj(request.address).line1 ?? null).toBeNull();
  expect(obj(request.customer).phone ?? null).toBeNull();
  const early = await get(`/v1/customer/bookings/${id}/start-code`, c);
  expect(early.code()).toBe('BOOKING_INVALID_TRANSITION');

  const accepted = await mustJob(p, id, 'accept');
  expect(accepted.status).toBe('accepted');
  expect(obj(accepted.address).line1 ?? null).not.toBeNull();
  expect(obj(accepted.customer).phone ?? null).not.toBeNull();
  const seen = (await get(`/v1/customer/bookings/${id}`, c)).expect(200);
  expect(seen.status).toBe('accepted');
  expect(obj(seen.provider).phone ?? null).not.toBeNull();
  return id;
}

// Walks on the way → arrived, enters two wrong start codes, then the right one.
async function arriveAndStartAfterTwoWrongCodes(c: Session, p: Partner, id: string) {
  const code = await startCode(c, id);
  await mustJob(p, id, 'on-the-way');
  expect(await customerStatus(c, id)).toBe('on_the_way');
  await mustJob(p, id, 'arrived');
  const n = Number(code);
  for (const i of [1, 2]) {
    const wrong = String((n + i) % 10000).padStart(4, '0');
    expect((await job(p, id, 'start', { code: wrong })).code()).toBe('START_CODE_INVALID');
  }
  expect(await customerStatus(c, id)).toBe('arrived');
  expect((await mustJob(p, id, 'start', { code })).status).toBe('in_progress');
}

// The provider proposes one extra item and the customer approves it; completing is
// refused while the proposal is pending. Returns the new total.
async function addApprovedExtras({ c, p, id }: Booked, before: number, extra: Sub) {
  const proposed = await mustJob(p, id, 'extras', { items: lines({ sub: extra, quantity: 1 }) });
  const pending = obj(proposed.pendingExtras);
  const total = before + extra.price;
  expect(pending).toMatchObject({ addedTotal: extra.price, newTotal: total, status: 'pending' });
  const early = await job(p, id, 'complete', { cashReceived: true });
  expect(early.code()).toBe('EXTRAS_PENDING');
  const decision = { proposalId: pending.id, approve: true };
  const path = `/v1/customer/bookings/${id}/extras/decision`;
  const decided = (await send('POST', path, decision, c)).expect(200);
  expect(decided.total).toBe(total);
  expect(list(decided.items)).toHaveLength(2);
  return total;
}

// Posts a review once the booking is reviewable: the rating module learns of the
// completion from the worker's relay a moment after the API answered.
async function review(s: Session, path: string, body: unknown): Promise<void> {
  await eventually(10_000, 'review accepted', async () => {
    const r = await send('POST', path, body, s);
    if (r.status !== 201 && r.code() !== 'REVIEW_NOT_ALLOWED') {
      throw new Error(`review ${path}: ${r.status} ${r.body}`);
    }
    return r.status === 201;
  });
}

// Each side reviews the other; the provider's rating follows.
async function rateBothWays(c: Session, p: Partner, id: string): Promise<void> {
  const customerReview = `/v1/customer/bookings/${id}/review`;
  await review(c, customerReview, {
    stars: 5,
    tags: ['on_time', 'professional'],
    comment: 'Fixed the fan quickly.',
  });
  await review(p.session, `/v1/provider/jobs/${id}/review`, {
    stars: 4,
    tags: ['polite', 'paid_promptly'],
  });
  expect((await send('POST', customerReview, { stars: 1 }, c)).status).toBe(409);
  expect((await get(`/v1/customer/bookings/${id}`, c)).expect(200).reviewedByMe).toBe(true);
  await eventually(10_000, 'provider rating updated', async () => {
    const r = (await get('/v1/provider/rating', p.session)).expect(200);
    return r.count === 1 && r.average === 5;
  });
}

// Compares both receipts with the booked and the extra lines.
async function checkReceipts({ c, p, id }: Booked, total: number, ls: Line[]) {
  const receipts: [Session, string][] = [
    [c, `/v1/customer/bookings/${id}/receipt`],
    [p.session, `/v1/provider/jobs/${id}/receipt`],
  ];
  const wantItems = ls.map((l, i) => ({
    subServiceId: l.sub.id,
    quantity: l.quantity,
    extra: i > 0,
    unitPrice: l.sub.price,
    total: l.sub.price * l.quantity,
  }));
  for (const [who, path] of receipts) {
    const rc = (await get(path, who)).expect(200);
    expect(rc).toMatchObject({
      total,
      paymentMethod: 'cash',
      providerName: 'Rahim Uddin',
      customerName: 'Nusrat Jahan',
    });
    const got = list(rc.items);
    expect(got).toHaveLength(2);
    got.forEach((it, i) => {
      expect(it).toMatchObject(wantItems[i] ?? {});
    });
  }
}

// The completed job is the provider's only earning.
async function checkEarnings(p: Partner, id: string, total: number): Promise<void> {
  const sum = (await get('/v1/provider/earnings/summary?period=week', p.session)).expect(200);
  expect(sum).toMatchObject({ total, jobs: 1 });
  expect(list(sum.buckets)).toHaveLength(7);
  const jobs = list((await get('/v1/provider/earnings/jobs', p.session)).expect(200).items);
  expect(jobs).toHaveLength(1);
  expect(jobs[0]).toMatchObject({ bookingId: id, total });
}

test('booking: from request to receipt with extras and ratings', async () => {
  const { session: c, address } = await customerAt(phoneFor('017', 11));
  const electrician = await catalogService(c, 'Electrician');
  const [fan, extra] = electrician.subs;
  if (fan === undefined || extra === undefined) {
    throw new Error(
      `electrician needs two sub-services for extras: ${JSON.stringify(electrician)}`,
    );
  }
  const p = await onlineProvider(12, electrician.id);
  await eventually(10_000, 'provider in nearby search', () =>
    nearby(c, electrician.id, fan.id, p.id),
  );
  const order = { customer: c, address, providerId: p.id, serviceId: electrician.id };

  const id = await requestAndAccept(order, p, fan);
  await arriveAndStartAfterTwoWrongCodes(c, p, id);
  const total = await addApprovedExtras({ c, p, id }, 2 * fan.price, extra);

  const unpaid = await job(p, id, 'complete', { cashReceived: false });
  expect(unpaid.code()).toBe('CASH_CONFIRMATION_REQUIRED');
  const done = await mustJob(p, id, 'complete', { cashReceived: true });
  expect(done).toMatchObject({ status: 'completed', total });
  await rateBothWays(c, p, id);
  await checkReceipts({ c, p, id }, total, [
    { sub: fan, quantity: 2 },
    { sub: extra, quantity: 1 },
  ]);
  await checkEarnings(p, id, total);
});
