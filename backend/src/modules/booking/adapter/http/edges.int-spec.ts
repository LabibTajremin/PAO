import type Redis from 'ioredis';
import { v7 as uuid } from 'uuid';
import { startTestApi, type TestApi } from '../../../../../test/kit/api';
import { electrician, fan, socket, World } from '../../../../../test/kit/booking-world';
import { DATABASE, type Database } from '../../../../platform/db/database';
import { REDIS } from '../../../../platform/redis/redis-client';
import { CreateBooking, type CreateInput } from '../../app/create-booking';
import { ProgressJob } from '../../app/progress';
import { RespondToRequests } from '../../app/respond';

describe('booking edges', () => {
  let api: TestApi;
  let w: World;

  beforeEach(async () => {
    api = await startTestApi();
    w = await World.create(api);
  });

  it('keeps each side to its own endpoints (TestBooking_Edges)', async () => {
    const both = { token: await api.token(w.provider.id, ['provider', 'customer']) };
    const id = await w.book('booking-edge-1');
    for (const path of [`/v1/customer/bookings/${id}`, `/v1/customer/bookings/${id}/start-code`]) {
      expect((await api.do('GET', path, undefined, both)).status).toBe(404);
    }
    const cancel = await api.do(
      'POST',
      `/v1/customer/bookings/${id}/cancel`,
      { reason: 'other' },
      both,
    );
    expect(cancel.status).toBe(404);
    expect((await w.job(uuid(), 'accept')).status).toBe(404);
    await w.job(id, 'reject', { reason: 'busy' });
    expect((await w.job(id, 'reject', { reason: 'busy' })).code).toBe('BOOKING_INVALID_TRANSITION');
    const custView = { token: await api.token(w.customer.id, ['customer', 'provider']) };
    const second = await w.book('booking-edge-2');
    const stolen = await api.do('POST', `/v1/provider/jobs/${second}/accept`, undefined, custView);
    expect(stolen.status).toBe(404);
    await w.run(second);
    expect((await w.job(second, 'on-the-way')).code).toBe('BOOKING_INVALID_TRANSITION');
    const extras = { items: [{ subServiceId: socket, quantity: 1 }] };
    const p1 = ((await w.job(second, 'extras', extras)).body?.pendingExtras as { id: string }).id;
    const path = `/v1/customer/bookings/${second}/extras/decision`;
    expect((await api.do('POST', path, { proposalId: p1, approve: true }, both)).status).toBe(404);
    await w.asCustomer('POST', path, { proposalId: p1, approve: false });
    expect((await w.job(second, 'extras', extras)).body?.pendingExtras).toBeDefined();
    await expect(
      api.app.get(ProgressJob).proposeExtras(w.provider.id, second, []),
    ).rejects.toThrow();
    await directCalls(api, w);
  });

  it('refuses unavailable providers and pages earnings (TestBooking_UnavailableAndEarningsPaging)', async () => {
    for (const key of ['booking-earn-1', 'booking-earn-2']) {
      const id = await w.book(key);
      await w.run(id);
      await w.job(id, 'complete', { cashReceived: true });
    }
    const page = await w.asProvider('GET', '/v1/provider/earnings/jobs?limit=1');
    expect(page.body?.items).toHaveLength(1);
    const cursor = page.body?.nextCursor as string;
    const next = await w.asProvider('GET', `/v1/provider/earnings/jobs?limit=1&cursor=${cursor}`);
    expect(next.body?.items).toHaveLength(1);
    await w.asProvider('POST', '/v1/provider/presence/offline');
    expect((await w.request('booking-offline')).code).toBe('PROVIDER_UNAVAILABLE');
    const db = api.app.get<Database>(DATABASE);
    await db.query('UPDATE catalog.services SET published = false WHERE id = $1', [electrician]);
    const near = w.nearby(`quantity=1&addressId=${w.addressId}`);
    expect((await w.asCustomer('GET', near)).code).toBe('PROVIDER_UNAVAILABLE');
    expect((await w.request('booking-unpublished')).code).toBe('PROVIDER_UNAVAILABLE');
    await api.app.get<Redis>(REDIS).del(api.keys.key('cache', 'settings'));
    await db.query('ALTER TABLE admin.settings RENAME TO gone');
    await expect(api.app.get(ProgressJob).start(w.provider.id, uuid(), '1234')).rejects.toThrow();
    await db.close();
    expect((await w.asCustomer('GET', `/v1/customer/bookings/${uuid()}`)).status).toBe(500);
  });
});

/** The use cases called directly, as the Go spec did. */
async function directCalls(api: TestApi, w: World) {
  const create = api.app.get(CreateBooking);
  const empty = { customerId: w.customer.id, idempotencyKey: '', items: [], note: '' };
  await expect(create.execute(empty as unknown as CreateInput)).rejects.toThrow();
  const input: CreateInput = {
    customerId: w.customer.id,
    providerId: w.provider.id,
    serviceId: electrician,
    addressId: w.addressId,
    items: [{ subServiceId: fan, quantity: 1 }],
    scheduledAt: null,
    note: '',
    idempotencyKey: 'booking-direct-key',
  };
  const first = await create.execute(input);
  expect(first.created).toBe(true);
  const again = await create.execute(input);
  expect(again.created).toBe(false);
  expect(again.booking.id).toBe(first.booking.id);
  await api.app.get(RespondToRequests).cancel('customer', w.customer.id, first.booking.id, 'other');
  const when = new Date(api.clock.now().getTime() + 2 * 3_600_000).toISOString();
  const items = [{ subServiceId: fan, quantity: 1 }];
  await w.book('booking-edge-scheduled', { timing: 'scheduled', scheduledAt: when, items });
  const up = await w.asCustomer('GET', '/v1/customer/bookings?tab=upcoming');
  expect((up.body?.items as unknown[]).length).toBeGreaterThanOrEqual(2);
}
