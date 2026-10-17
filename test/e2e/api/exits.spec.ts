import { customerAt, phoneFor } from './support/actors';
import {
  bookASAP,
  customerStatus,
  job,
  mustJob,
  onlineProvider,
  pushed,
  setSetting,
  startJob,
  type Order,
  type Partner,
} from './support/booking';
import { eventually, get, send, type Session } from './support/client';
import { str } from './support/json';
import { catalogService, firstSub, type Offer } from './support/provider';

// A customer next to an online electrician, ready to book.
interface World {
  readonly c: Session;
  readonly p: Partner;
  readonly svc: Offer;
  book(): Promise<string>;
}

async function newWorld(n: number): Promise<World> {
  const { session: c, address } = await customerAt(phoneFor('017', n));
  const svc = await catalogService(c, 'Electrician');
  const p = await onlineProvider(n + 1, svc.id);
  const order: Order = { customer: c, address, providerId: p.id, serviceId: svc.id };
  const book = async () => str((await bookASAP(order, { sub: firstSub(svc), quantity: 1 })).id);
  return { c, p, svc, book };
}

const cancelBody = { reason: 'changed_mind' };

test('booking: provider rejects and the customer sees it', async () => {
  const w = await newWorld(21);
  const id = await w.book();
  expect((await job(w.p, id, 'reject', {})).status).toBe(422);
  expect(await mustJob(w.p, id, 'reject', { reason: 'too_far' })).toMatchObject({
    status: 'rejected',
  });
  const seen = (await get(`/v1/customer/bookings/${id}`, w.c)).expect(200);
  expect(seen).toMatchObject({ status: 'rejected', cancellable: false });
  expect((await job(w.p, id, 'accept')).code()).toBe('BOOKING_INVALID_TRANSITION');
  // A rejected request is closed, so the customer may ask the same provider again.
  await w.book();
});

test('booking: an unanswered request times out', async () => {
  const w = await newWorld(23);
  await setSetting('booking.accept_timeout_asap_seconds', '1');
  const id = await w.book();
  // The worker sweeps expired requests every 15 seconds.
  await eventually(40_000, 'request timed out', async () => {
    return (await customerStatus(w.c, id)) === 'timed_out';
  });
  expect((await job(w.p, id, 'accept')).code()).toBe('BOOKING_INVALID_TRANSITION');
  await eventually(10_000, 'missed request pushed', () =>
    pushed(w.p.pushToken, 'request_missed', id),
  );
});

test('booking: the customer cancels before the start', async () => {
  const w = await newWorld(25);
  const cancel = async (id: string) =>
    (await send('POST', `/v1/customer/bookings/${id}/cancel`, cancelBody, w.c)).expect(200);

  const requested = await w.book();
  expect(await cancel(requested)).toMatchObject({ status: 'cancelled' });

  const accepted = await w.book();
  await mustJob(w.p, accepted, 'accept');
  await mustJob(w.p, accepted, 'on-the-way');
  expect(await cancel(accepted)).toMatchObject({ status: 'cancelled' });
  const providerView = (await get(`/v1/provider/jobs/${accepted}`, w.p.session)).expect(200);
  expect(providerView.status).toBe('cancelled');
  await eventually(10_000, 'cancellation pushed', () =>
    pushed(w.p.pushToken, 'booking_cancelled', accepted),
  );
});

test('booking: cancellation is blocked once started', async () => {
  const w = await newWorld(27);
  const id = await w.book();
  await mustJob(w.p, id, 'accept');
  await startJob(w.c, w.p, id);

  const r = await send('POST', `/v1/customer/bookings/${id}/cancel`, cancelBody, w.c);
  expect({ status: r.status, code: r.code() }).toEqual({
    status: 409,
    code: 'CANCELLATION_NOT_ALLOWED',
  });
  expect((await job(w.p, id, 'cancel', { reason: 'emergency' })).status).toBe(409);
  const seen = (await get(`/v1/customer/bookings/${id}`, w.c)).expect(200);
  expect(seen).toMatchObject({ status: 'in_progress', cancellable: false });
  await mustJob(w.p, id, 'complete', { cashReceived: true });
});
