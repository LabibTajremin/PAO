import { customerAt, phoneFor } from './support/actors';
import { bookASAP, onlineProvider, pushed } from './support/booking';
import { send, sleep } from './support/client';
import { str } from './support/json';
import { catalogService, firstSub } from './support/provider';

// PRD §11: a booking request reaches the provider's phone within 3 seconds. Measured
// from the create call returning to the push showing up in the worker's capture, over
// sequential requests.
test('latency: a request reaches the provider within 3 s', async () => {
  const samples = 10;
  const limitMs = 3000;
  const { session: c, address } = await customerAt(phoneFor('017', 61));
  const svc = await catalogService(c, 'Electrician');
  const p = await onlineProvider(62, svc.id);
  const order = { customer: c, address, providerId: p.id, serviceId: svc.id };
  const took: number[] = [];
  for (let i = 0; i < samples; i++) {
    const id = str((await bookASAP(order, { sub: firstSub(svc), quantity: 1 })).id);
    const start = performance.now();
    while (!(await pushed(p.pushToken, 'booking_requested', id))) {
      if (performance.now() - start > 2 * limitMs) {
        throw new Error(`no push for ${id} after ${2 * limitMs} ms`);
      }
      await sleep(50);
    }
    took.push(performance.now() - start);
    // The customer may hold one open request per provider; close this one first.
    const cancel = { reason: 'booked_by_mistake' };
    (await send('POST', `/v1/customer/bookings/${id}/cancel`, cancel, c)).expect(200);
  }
  // With ten samples the 95th percentile is the slowest one.
  const p95 = Math.max(...took);
  process.stdout.write(
    `request → push ms: ${took.map(Math.round).join(', ')} (p95 ${Math.round(p95)})\n`,
  );
  expect(p95).toBeLessThan(limitMs);
});
