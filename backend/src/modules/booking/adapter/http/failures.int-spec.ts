import { v7 as uuid } from 'uuid';
import { startTestApi, type TestApi } from '../../../../../test/kit/api';
import { electrician, fan, World } from '../../../../../test/kit/booking-world';
import { upload } from '../../../../../test/kit/media';
import { verifiedProvider } from '../../../../../test/kit/provider';
import { DATABASE, type Database } from '../../../../platform/db/database';
import { isDomainError } from '../../../../platform/errors/domain-error';
import { RespondToRequests } from '../../app/respond';
import { BOOKING_SERVICE, BookingErrors, type BookingService } from '../../contract';

describe('booking ownership, contract and failures (TestBooking_OwnershipContractAndFailures)', () => {
  let api: TestApi;
  let w: World;
  let bookings: BookingService;
  let id: string;

  beforeAll(async () => {
    api = await startTestApi();
    w = await World.create(api);
    bookings = api.app.get(BOOKING_SERVICE);
    const photo = await upload(api, w.provider.id, 'provider', 'avatar');
    await w.asProvider('PUT', '/v1/provider/profile', { language: 'bn', photoMediaId: photo });
    id = await w.book('booking-owner-1');
  });

  it('shows the provider photo on the nearby card', async () => {
    const near = await w.asCustomer('GET', w.nearby(`quantity=1&addressId=${w.addressId}`));
    const [card] = near.body?.items as Record<string, unknown>[];
    expect(card?.photoUrl).toBeDefined();
  });

  it('hides the booking from everyone else', async () => {
    const other = await verifiedProvider(api, '01712345688', 'male', electrician);
    for (const action of ['reject', 'on-the-way', 'arrived']) {
      const r = await api.do(
        'POST',
        `/v1/provider/jobs/${id}/${action}`,
        { reason: 'busy' },
        {
          token: other.token,
        },
      );
      expect(`${action} ${String(r.status)}`).toBe(`${action} 404`);
    }
    for (const path of [`/v1/provider/jobs/${id}`, `/v1/provider/jobs/${id}/receipt`]) {
      expect((await api.do('GET', path, undefined, { token: other.token })).status).toBe(404);
    }
    const asCustomer = await w.asCustomer('GET', `/v1/provider/jobs/${id}`);
    expect([403, 404]).toContain(asCustomer.status);
    const stranger = { token: await api.token(uuid(), ['customer']) };
    const base = `/v1/customer/bookings/${id}`;
    expect((await api.do('GET', `${base}/start-code`, undefined, stranger)).status).toBe(404);
    expect((await api.do('POST', `${base}/cancel`, { reason: 'other' }, stranger)).status).toBe(
      404,
    );
    const decision = { proposalId: uuid(), approve: true };
    const decided = await api.do('POST', `${base}/extras/decision`, decision, stranger);
    expect(decided.status).toBe(404);
    const extras = await w.job(id, 'extras', { items: [{ subServiceId: fan, quantity: 1 }] });
    expect(extras.code).toBe('BOOKING_INVALID_TRANSITION');
  });

  it('serves the contract', async () => {
    const b = await bookings.getBooking(id);
    expect(b).toMatchObject({ status: 'requested', customerName: 'Nusrat Jahan' });
    expect(b.number).toMatch(/^PAO-\d+$/);
    const missing = await bookings.getBooking(uuid()).catch((e: unknown) => e);
    expect(isDomainError(missing, BookingErrors.NotFound)).toBe(true);
    expect(await bookings.listRecentBookings(w.provider.id, 5)).toHaveLength(1);
  });

  it('answers earnings by date and refuses bad cursors', async () => {
    const day = await w.asProvider(
      'GET',
      '/v1/provider/earnings/summary?period=day&date=2026-01-01',
    );
    expect(day.body?.jobs).toBe(0);
    const range = '/v1/provider/earnings/jobs?from=2026-01-01&to=2026-12-31&limit=1';
    expect((await w.asProvider('GET', range)).status).toBe(200);
    expect((await w.asCustomer('GET', '/v1/customer/bookings?tab=past&cursor=%25')).status).toBe(
      422,
    );
    for (const path of [
      '/v1/provider/jobs?tab=past&cursor=%25',
      '/v1/provider/earnings/jobs?cursor=%25',
    ]) {
      expect((await w.asProvider('GET', path)).status).toBe(422);
    }
  });

  it('answers 500 once the database is gone', async () => {
    const db = api.app.get<Database>(DATABASE);
    // The open request would make a second one a duplicate rather than a failure.
    await w.asCustomer('POST', `/v1/customer/bookings/${id}/cancel`, { reason: 'other' });
    await db.query('ALTER TABLE booking.booking_items RENAME TO items_gone');
    expect((await w.request('booking-without-items')).status).toBe(500);
    await db.close();
    expect((await w.asCustomer('GET', '/v1/customer/bookings?tab=upcoming')).status).toBe(500);
    for (const path of [
      '/v1/provider/jobs?tab=requests',
      '/v1/provider/earnings/jobs',
      '/v1/provider/earnings/summary?period=month',
    ]) {
      expect(`${path} ${String((await w.asProvider('GET', path)).status)}`).toBe(`${path} 500`);
    }
    await expect(api.app.get(RespondToRequests).expireDue()).rejects.toThrow();
    await expect(bookings.listRecentBookings(w.provider.id, 5)).rejects.toThrow();
  });
});
