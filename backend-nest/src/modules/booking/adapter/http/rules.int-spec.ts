import { v7 as uuid } from 'uuid';
import { startTestApi, type TestApi } from '../../../../../test/kit/api';
import { fan, tap, World } from '../../../../../test/kit/booking-world';
import { adminSession } from '../../../../../test/kit/identity';
import { near, service, verifiedProvider } from '../../../../../test/kit/provider';
import { seedId } from '../../../catalog/app/seed-catalog';
import { CreateBooking, type CreateInput } from '../../app/create-booking';

const TEN_MINUTES = 10 * 60_000;

describe('booking rules', () => {
  let api: TestApi;
  let w: World;

  beforeEach(async () => {
    api = await startTestApi();
    w = await World.create(api);
  });

  it('refuses bad requests (TestBooking_CreateRules)', async () => {
    const past = new Date(api.clock.now().getTime() - 3_600_000).toISOString();
    const cases: [Record<string, unknown>, string][] = [
      [{ timing: 'scheduled' }, 'VALIDATION_FAILED'],
      [{ timing: 'scheduled', scheduledAt: past }, 'VALIDATION_FAILED'],
      [{ items: [{ subServiceId: tap, quantity: 1 }] }, 'VALIDATION_FAILED'],
      [{ items: [{ subServiceId: fan, quantity: 11 }] }, 'VALIDATION_FAILED'],
      [{ items: [{ subServiceId: uuid(), quantity: 1 }] }, 'VALIDATION_FAILED'],
      [{ serviceId: uuid() }, 'NOT_FOUND'],
      [{ addressId: uuid() }, 'VALIDATION_FAILED'],
      [{ providerId: uuid() }, 'PROVIDER_UNAVAILABLE'],
    ];
    for (const [i, [extra, code]] of cases.entries()) {
      const r = await w.request(`booking-rules-${String(i)}`, extra);
      expect(`${JSON.stringify(extra)} ${String(r.code)}`).toBe(`${JSON.stringify(extra)} ${code}`);
    }
    const stranger = await api.token(uuid(), ['customer']);
    expect((await w.request('booking-rules-x', {}, stranger)).code).toBe('PROFILE_REQUIRED');
  });

  it('keeps bookings and searches inside the launch area (TestBooking_CreateRules)', async () => {
    const area = '{"type":"Polygon","coordinates":[[[91,22],[92,22],[92,23],[91,22]]]}';
    const token = (await adminSession(api, ['super_admin'])).accessToken;
    const setting = '/v1/admin/settings/service_area.geojson';
    await api.do('PUT', setting, { value: area }, { token });
    expect((await w.request('booking-area')).code).toBe('OUTSIDE_SERVICE_AREA');
    const point = w.nearby('quantity=1&lat=23.79&lng=90.40');
    expect((await w.asCustomer('GET', point)).code).toBe('OUTSIDE_SERVICE_AREA');
    await api.do('PUT', setting, { value: '' }, { token });
    expect((await w.asCustomer('GET', `${point}&sort=rating`)).body?.items).toHaveLength(1);
    expect((await w.asCustomer('GET', w.nearby('quantity=1'))).status).toBe(422);
    expect((await w.asCustomer('GET', `/v1/customer/bookings/${uuid()}`)).status).toBe(404);
  });

  it('locks the start code and books duration hires (TestBooking_StartCodeLockoutAndDurationHire)', async () => {
    const id = await w.book('booking-lockout');
    await w.job(id, 'accept');
    const code = await w.code(id);
    const wrong = code === '0000' ? '1111' : '0000';
    expect((await w.job(id, 'start', { code })).code).toBe('BOOKING_INVALID_TRANSITION');
    await w.job(id, 'on-the-way');
    await w.job(id, 'arrived');
    for (let i = 0; i < 5; i++) {
      await w.job(id, 'start', { code: wrong });
    }
    expect((await w.job(id, 'start', { code })).code).toBe('START_CODE_LOCKED');
    api.clock.advance(TEN_MINUTES);
    await w.refreshTokens();
    expect((await w.job(id, 'start', { code })).body?.status).toBe('in_progress');
    const otherService = { items: [{ subServiceId: tap, quantity: 1 }] };
    expect((await w.job(id, 'extras', otherService)).code).toBe('VALIDATION_FAILED');
    const decision = { proposalId: uuid(), approve: true };
    const base = `/v1/customer/bookings/${id}`;
    expect((await w.asCustomer('POST', `${base}/extras/decision`, decision)).code).toBe(
      'NO_PENDING_EXTRAS',
    );
    expect((await w.asCustomer('GET', `${base}/receipt`)).code).toBe('BOOKING_INVALID_TRANSITION');
    await durationHire(api, w);
  });
});

async function durationHire(api: TestApi, w: World) {
  const driver = service('driver');
  const create = api.app.get(CreateBooking);
  const input: CreateInput = {
    customerId: w.customer.id,
    providerId: w.provider.id,
    serviceId: driver,
    addressId: w.addressId,
    items: [{ subServiceId: seedId('sub-service', 'driver-day'), quantity: 1 }],
    scheduledAt: null,
    note: '',
    idempotencyKey: 'booking-app-driver',
  };
  await expect(create.execute(input)).rejects.toThrow();
  const pro = await verifiedProvider(api, '01712345699', 'male', driver);
  await api.do('POST', '/v1/provider/presence/online', near, { token: pro.token });
  const { booking, created } = await create.execute({ ...input, providerId: pro.id });
  expect(created).toBe(true);
  expect((booking.endsAt?.getTime() ?? 0) - booking.createdAt.getTime()).toBe(86_400_000);
}
