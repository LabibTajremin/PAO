// Booking helpers: a customer with a Banani address, and a
// job between them and a verified, online electrician.
import { randomUUID } from 'node:crypto';
import { type TestApi } from './api';
import { seedCatalog } from './catalog';
import { relayEvents } from './events';
import { signIn } from './identity';
import { near, type ProviderSession, service, verifiedProvider } from './provider';
import { seedId } from '../../src/modules/catalog/app/seed-catalog';

/** A signed-in customer. */
export interface CustomerSession {
  readonly id: string;
  readonly token: string;
}

/** A booking between a verified electrician and a customer. */
export interface Job {
  readonly id: string;
  readonly provider: ProviderSession;
  readonly customer: CustomerSession;
}

/** The Banani address test customers save. */
export const BANANI = {
  label: 'home',
  line1: 'House 12, Road 5',
  area: 'Banani',
  location: { lat: 23.7937, lng: 90.4066 },
};

async function call(api: TestApi, route: string, body: unknown, token: string) {
  const [method = '', path = ''] = route.split(' ');
  const r = await api.do(method, path, body, { token });
  if (r.status >= 300) {
    throw new Error(`${route}: ${String(r.status)} ${r.text}`);
  }
  return r.body ?? {};
}

/** Signs a customer in with a profile and a Banani address; returns them and its id. */
export async function customer(
  api: TestApi,
  phone: string,
  language = 'en',
): Promise<{ customer: CustomerSession; addressId: string }> {
  const tp = await signIn(api, phone, 'customer');
  const c = { id: tp.account.id, token: tp.accessToken };
  await call(api, 'PUT /v1/customer/profile', { name: 'Nusrat Jahan', language }, c.token);
  const address = await call(api, 'POST /v1/customer/addresses', BANANI, c.token);
  return { customer: c, addressId: address.id as string };
}

/**
 * Seeds the catalog and has a new customer request a new, online electrician (who must
 * not exist yet: phones are fixed per call site).
 */
export async function requestedJob(
  api: TestApi,
  providerPhone: string,
  customerPhone: string,
): Promise<Job> {
  await seedCatalog(api);
  const electrician = service('electrician');
  const p = await verifiedProvider(api, providerPhone, 'male', electrician);
  await call(api, 'POST /v1/provider/presence/online', near, p.token);
  const { customer: c, addressId } = await customer(api, customerPhone);
  const body = {
    providerId: p.id,
    serviceId: electrician,
    timing: 'asap',
    addressId,
    items: [{ subServiceId: seedId('sub-service', 'fan-install'), quantity: 1 }],
  };
  const r = await api.do('POST', '/v1/customer/bookings', body, {
    token: c.token,
    headers: { 'Idempotency-Key': `job-${randomUUID()}` },
  });
  if (r.status !== 201) {
    throw new Error(`book: ${String(r.status)} ${r.text}`);
  }
  return { id: r.body?.id as string, provider: p, customer: c };
}

/** Runs a requested job through acceptance, start and completion. */
export async function completedJob(
  api: TestApi,
  providerPhone: string,
  customerPhone: string,
): Promise<Job> {
  const j = await requestedJob(api, providerPhone, customerPhone);
  const path = `/v1/provider/jobs/${j.id}`;
  await call(api, `POST ${path}/accept`, undefined, j.provider.token);
  const code = await call(
    api,
    `GET /v1/customer/bookings/${j.id}/start-code`,
    undefined,
    j.customer.token,
  );
  await call(api, `POST ${path}/on-the-way`, undefined, j.provider.token);
  await call(api, `POST ${path}/arrived`, undefined, j.provider.token);
  await call(api, `POST ${path}/start`, { code: code.code }, j.provider.token);
  await call(api, `POST ${path}/complete`, { cashReceived: true }, j.provider.token);
  await relayEvents(api);
  return j;
}
