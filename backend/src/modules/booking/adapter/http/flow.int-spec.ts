import { startTestApi, type TestApi } from '../../../../../test/kit/api';
import { socket, World } from '../../../../../test/kit/booking-world';
import { relayEvents } from '../../../../../test/kit/events';
import { HEALTH_ROUTES } from '../../../../platform/health/health';
import { checkRoutesAgainstSpec } from '../../../../platform/http/route-spec-check';
import { OPENAPI_DOCUMENT } from '../../../../platform/http/spec-routes';
import { BOOKING_SERVICE, type BookingService } from '../../contract';

type Json = Record<string, unknown>;

/** Searches, books and has the provider accept; checks privacy on the way. */
async function bookAndAccept(w: World): Promise<string> {
  const near = await w.asCustomer('GET', w.nearby(`quantity=2&addressId=${w.addressId}`));
  expect(near.status).toBe(200);
  expect(near.body?.items).toHaveLength(1);
  expect((near.body?.priceSummary as Json).total).toBe(100000);
  const id = await w.book('booking-key-1');
  const before = (await w.asProvider('GET', `/v1/provider/jobs/${id}`)).body as Json;
  expect((before.address as Json).line1).toBeUndefined();
  expect((before.customer as Json).phone).toBeUndefined();
  const early = await w.asCustomer('GET', `/v1/customer/bookings/${id}/start-code`);
  expect(early.code).toBe('BOOKING_INVALID_TRANSITION');
  const accepted = (await w.job(id, 'accept')).body as Json;
  expect(accepted.status).toBe('accepted');
  expect((accepted.address as Json).line1).toBe('House 12, Road 5');
  expect((accepted.customer as Json).phone).toBeDefined();
  return id;
}

/** Starts the job and has the customer approve one extra item. */
async function startWithExtras(w: World, id: string): Promise<void> {
  const code = await w.code(id);
  await w.job(id, 'on-the-way');
  await w.job(id, 'arrived');
  const wrong = code === '0000' ? '1111' : '0000';
  expect((await w.job(id, 'start', { code: wrong })).code).toBe('START_CODE_INVALID');
  expect((await w.job(id, 'start', { code })).body?.status).toBe('in_progress');
  const extras = await w.job(id, 'extras', { items: [{ subServiceId: socket, quantity: 1 }] });
  const pending = extras.body?.pendingExtras as Json;
  expect(pending).toMatchObject({ addedTotal: 35000, newTotal: 135000 });
  expect((await w.job(id, 'complete', { cashReceived: true })).code).toBe('EXTRAS_PENDING');
  const decision = { proposalId: pending.id, approve: true };
  const path = `/v1/customer/bookings/${id}/extras/decision`;
  expect((await w.asCustomer('POST', path, decision)).body?.total).toBe(135000);
  expect((await w.job(id, 'complete', { cashReceived: false })).code).toBe(
    'CASH_CONFIRMATION_REQUIRED',
  );
}

describe('booking flow', () => {
  let api: TestApi;
  let w: World;

  beforeEach(async () => {
    api = await startTestApi();
    w = await World.create(api);
  });

  it('serves every booking operation with the spec permission', () => {
    const report = checkRoutesAgainstSpec(api.app, api.app.get(OPENAPI_DOCUMENT), HEALTH_ROUTES);
    expect(report.mismatched).toEqual([]);
    expect(report.undocumented).toEqual([]);
    const ours =
      /\/v1\/(customer\/bookings|provider\/jobs|provider\/earnings|admin\/bookings|customer\/providers\/nearby)/;
    const unserved = report.unserved.filter(
      (op) => ours.test(op) && !/\/(review|reports)$/.test(op),
    );
    expect(unserved).toEqual([]);
  });

  it('runs a job with extras to the receipt (TestBooking_HappyPathWithExtras)', async () => {
    const id = await bookAndAccept(w);
    await startWithExtras(w, id);
    const done = (await w.job(id, 'complete', { cashReceived: true })).body as Json;
    expect(done.status).toBe('completed');
    expect(done.items).toHaveLength(2);
    expect(done.timeline).toHaveLength(6);
    const receipt = await w.asCustomer('GET', `/v1/customer/bookings/${id}/receipt`);
    expect(receipt.body).toMatchObject({ total: 135000, providerName: 'Rahim Uddin' });
    expect((await w.asProvider('GET', `/v1/provider/jobs/${id}/receipt`)).status).toBe(200);
    const detail = await w.asCustomer('GET', `/v1/customer/bookings/${id}`);
    expect(detail.body?.reviewedByMe).toBe(false);
    const sum = (await w.asProvider('GET', '/v1/provider/earnings/summary?period=week')).body;
    expect(sum).toMatchObject({ total: 135000, jobs: 1 });
    expect(sum?.buckets).toHaveLength(7);
    const jobs = await w.asProvider('GET', '/v1/provider/earnings/jobs');
    expect(jobs.body?.items).toHaveLength(1);
    const past = await w.asCustomer('GET', '/v1/customer/bookings?tab=past');
    expect(past.body?.items).toHaveLength(1);
    await relayEvents(api);
    const bookings = api.app.get<BookingService>(BOOKING_SERVICE);
    expect((await bookings.getProviderStats(w.provider.id)).completedJobs).toBe(1);
  });
});
