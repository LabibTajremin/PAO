import type Redis from 'ioredis';
import { v7 as uuid } from 'uuid';
import { startTestApi, type TestApi } from '../../../../../test/kit/api';
import { deliver, relayEvents, subscribedBus } from '../../../../../test/kit/events';
import { lastCode, signIn, signInAgain } from '../../../../../test/kit/identity';
import { DATABASE, type Database } from '../../../../platform/db/database';
import { REDIS } from '../../../../platform/redis/redis-client';
import { IdentityEvents } from '../../../identity/contract/events';
import { CUSTOMER_SERVICE, CustomerErrors, type CustomerService } from '../../contract';

const PHONE = '01712345678';
const profile = { name: 'Nusrat Jahan', language: 'bn' };
const home = {
  label: 'home',
  line1: 'House 12, Road 5',
  location: { lat: 23.7937, lng: 90.4066 },
};

describe('customer profile', () => {
  let api: TestApi;
  let customers: CustomerService;
  let db: Database;

  beforeAll(async () => {
    api = await startTestApi();
    customers = api.app.get(CUSTOMER_SERVICE);
    db = api.app.get(DATABASE);
  });

  // TestCustomer_ProfileWithPhotoAndDeletion, without the photo steps (media pending).
  it('needs a profile first, saves it and erases it with the account', async () => {
    const tp = await signIn(api, PHONE, 'customer');
    const token = tp.accessToken;
    const none = await api.do('GET', '/v1/customer/profile', undefined, { token });
    expect(none.code).toBe('PROFILE_NOT_FOUND');
    const early = await api.do('POST', '/v1/customer/addresses', home, { token });
    expect(early.code).toBe('PROFILE_REQUIRED');
    const saved = await api.do(
      'PUT',
      '/v1/customer/profile',
      { name: 'Nusrat', language: 'en' },
      { token },
    );
    expect(saved).toMatchObject({ status: 200, body: { phone: '+8801712345678', language: 'en' } });
    expect(saved.body).not.toHaveProperty('photoUrl');
    const got = await api.do('GET', '/v1/customer/profile', undefined, { token });
    expect(got.body?.language).toBe('en');
    const short = await api.do(
      'PUT',
      '/v1/customer/profile',
      { name: 'N', language: 'bn' },
      { token },
    );
    expect(short.status).toBe(422);
    await api.do('POST', '/v1/customer/addresses', home, { token });
    expect(await customers.getCustomer(tp.account.id)).toMatchObject({
      name: 'Nusrat',
      photoMediaId: null,
    });

    api.clock.advance(60_000);
    await api.do('POST', '/v1/auth/otp/request', { phone: PHONE, purpose: 'delete_account' });
    const code = lastCode(api, PHONE);
    expect((await api.do('DELETE', '/v1/me', { code }, { token })).status).toBe(204);
    await relayEvents(api);
    await expect(customers.getCustomer(tp.account.id)).rejects.toMatchObject({
      reason: CustomerErrors.NotFound,
    });
    const left = await db.query<{ n: string }>(
      'SELECT count(*) AS n FROM customer.addresses WHERE customer_id = $1',
      [tp.account.id],
    );
    expect(left.rows[0]?.n).toBe('0');
  });

  it('keeps the admin list copies current from events', async () => {
    const tp = await signIn(api, '01712345670', 'customer');
    await api.do('PUT', '/v1/customer/profile', profile, { token: tp.accessToken });
    const id = tp.account.id;
    await deliver(api, {
      name: IdentityEvents.AccountStatusChanged,
      accountId: id,
      from: 'active',
      to: 'suspended',
      reason: 'test',
      actorId: null,
      roles: ['customer'],
    } as never);
    await deliver(api, {
      name: IdentityEvents.AccountStatusChanged,
      accountId: id,
      from: 'suspended',
      to: 'banned',
      reason: 'provider only',
      actorId: null,
      roles: ['provider'],
    } as never);
    await deliver(api, { name: 'booking.BookingRequested', customerId: id } as never);
    await deliver(api, { name: 'booking.BookingRequested' } as never);
    const [row] = await customers.searchCustomers({
      id,
      text: ' NUSRAT ',
      status: 'suspended',
      afterAt: null,
      afterId: null,
      limit: 10,
    });
    expect(row).toMatchObject({ id, status: 'suspended', bookings: 1, phone: '+8801712345670' });
    const literal = { id: null, text: 'Nus%', status: '', afterAt: null, afterId: null, limit: 10 };
    expect(await customers.searchCustomers(literal)).toEqual([]);
  });

  // TestCustomer_ContractAndPeerFailures, without the media steps.
  it('reports contract misses and fails cleanly when stores break', async () => {
    await expect(customers.getAddress(uuid(), uuid())).rejects.toMatchObject({
      reason: CustomerErrors.AddressNotFound,
    });
    expect(await customers.isInServiceArea({ lat: 23.8, lng: 90.4 })).toBe(true);
    const ghost = await api.token(uuid(), ['customer']);
    expect((await api.do('PUT', '/v1/customer/profile', profile, { token: ghost })).status).toBe(
      500,
    );
    const broken = {
      id: uuid(),
      module: 'test',
      name: IdentityEvents.AccountDeleted,
      aggregateId: '',
      payload: {},
      occurredAt: new Date(),
    };
    const bus = subscribedBus(api);
    await expect(bus.dispatch(broken as never)).rejects.toThrow('accountId is missing');

    await signIn(api, '01712345671', 'customer');
    const again = (await signInAgain(api, '01712345671', 'customer')).accessToken;
    await api.do('PUT', '/v1/customer/profile', profile, { token: again });
    await db.query('ALTER TABLE customer.addresses RENAME TO gone');
    expect((await api.do('POST', '/v1/customer/addresses', home, { token: again })).status).toBe(
      500,
    );
    await db.query('ALTER TABLE customer.gone RENAME TO addresses');

    await api.app.get<Redis>(REDIS).del(api.keys.key('cache', 'settings'));
    await db.close();
    for (const path of ['/v1/customer/addresses', '/v1/customer/service-area?lat=23.8&lng=90.4']) {
      expect((await api.do('GET', path, undefined, { token: ghost })).status).toBe(500);
    }
  });
});
