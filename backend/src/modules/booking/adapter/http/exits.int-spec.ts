import { startTestApi, type TestApi } from '../../../../../test/kit/api';
import { World } from '../../../../../test/kit/booking-world';
import { relayEvents } from '../../../../../test/kit/events';
import { type JobScheduler } from '../../../../platform/jobs/scheduler';
import { BOOKING_SERVICE, type BookingService } from '../../contract';
import { BookingWorker, EXPIRE_EVERY_MS } from '../inproc/booking-contract';

/** Runs the worker's expiry job once, as the scheduler would. */
async function expireNow(api: TestApi): Promise<void> {
  const jobs: { ms: number; name: string; run: () => Promise<void> }[] = [];
  const scheduler = {
    every: (ms: number, name: string, run: () => Promise<void>) => jobs.push({ ms, name, run }),
  };
  api.app.get(BookingWorker).schedule(scheduler as unknown as JobScheduler);
  expect(jobs.map((j) => [j.ms, j.name])).toEqual([[EXPIRE_EVERY_MS, 'booking.expire_requests']]);
  await jobs[0]?.run();
}

describe('booking exits', () => {
  let api: TestApi;
  let w: World;

  beforeEach(async () => {
    api = await startTestApi();
    w = await World.create(api);
  });

  it('rejects, times out and cancels (TestBooking_RejectTimeoutCancel)', async () => {
    const rejected = await w.book('booking-reject');
    const r = await w.job(rejected, 'reject', { reason: 'busy', note: 'Another job' });
    expect(r.body?.status).toBe('rejected');
    const timedOut = await w.book('booking-timeout');
    api.clock.advance(3 * 60_000);
    await expireNow(api);
    await w.refreshTokens();
    const late = await w.asCustomer('GET', `/v1/customer/bookings/${timedOut}`);
    expect(late.body?.status).toBe('timed_out');
    expect((await w.job(timedOut, 'accept')).code).toBe('BOOKING_INVALID_TRANSITION');
    const free = await w.book('booking-cancel-free');
    const cancel = { reason: 'changed_mind' };
    const freed = await w.asCustomer('POST', `/v1/customer/bookings/${free}/cancel`, cancel);
    expect(freed.body?.status).toBe('cancelled');
    const again = await w.job(free, 'cancel', { reason: 'emergency' });
    expect(again.code).toBe('BOOKING_INVALID_TRANSITION');
    const byProvider = await w.book('booking-cancel-provider');
    await w.job(byProvider, 'accept');
    expect((await w.job(byProvider, 'cancel', { reason: 'emergency' })).body?.status).toBe(
      'cancelled',
    );
    const started = await w.book('booking-started');
    await w.run(started);
    const refused = await w.asCustomer('POST', `/v1/customer/bookings/${started}/cancel`, cancel);
    expect(refused.code).toBe('CANCELLATION_NOT_ALLOWED');
    await checkCounters(api, w);
  });

  it('replays a key and lets one accept win (TestBooking_IdempotencyAndConcurrentAccepts)', async () => {
    const first = await w.book('booking-same-key');
    expect(await w.book('booking-same-key')).toBe(first);
    expect((await w.request('booking-other-key')).code).toBe('DUPLICATE_BOOKING_REQUEST');
    const answers = await Promise.all([1, 2, 3, 4, 5].map(() => w.job(first, 'accept')));
    expect(answers.filter((a) => a.status === 200)).toHaveLength(1);
    const asap = await w.book('booking-second-asap');
    expect((await w.job(asap, 'accept')).code).toBe('ACTIVE_JOB_EXISTS');
    await w.job(asap, 'reject', { reason: 'busy' });
    const when = new Date(api.clock.now().getTime() + 86_400_000).toISOString();
    const scheduled = await w.book('booking-scheduled', { timing: 'scheduled', scheduledAt: when });
    expect((await w.job(scheduled, 'accept')).body?.status).toBe('accepted');
  });
});

async function checkCounters(api: TestApi, w: World) {
  await relayEvents(api);
  const bookings = api.app.get<BookingService>(BOOKING_SERVICE);
  expect((await bookings.getProviderStats(w.provider.id)).cancellations30d).toBe(1);
  expect(await bookings.countActiveJobs(w.provider.id)).toBe(1);
  const up = await w.asProvider('GET', '/v1/provider/jobs?tab=upcoming');
  expect(up.body?.items).toHaveLength(1);
  const past = await w.asProvider('GET', '/v1/provider/jobs?tab=past&limit=2');
  expect(past.body?.items).toHaveLength(2);
  const cursor = past.body?.nextCursor as string;
  const more = await w.asProvider('GET', `/v1/provider/jobs?tab=past&limit=2&cursor=${cursor}`);
  expect(more.body?.items).toHaveLength(2);
}
