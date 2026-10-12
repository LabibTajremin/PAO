// The scene of the booking integration specs (the Go booking setup_integration_test.go):
// one verified electrician online next to a customer with a saved Banani address.
import { seedId } from '../../src/modules/catalog/app/seed-catalog';
import { type TestApi } from './api';
import { customer, type CustomerSession } from './booking';
import { seedCatalog } from './catalog';
import { near, type ProviderSession, service, verifiedProvider } from './provider';

export const electrician = service('electrician');
export const fan = seedId('sub-service', 'fan-install');
export const socket = seedId('sub-service', 'socket-install');
export const tap = seedId('sub-service', 'tap-repair');

/** A provider and a customer ready to book each other. */
export class World {
  /** Bearers; {@link refreshTokens} replaces them after the clock passes their expiry. */
  providerToken: string;
  customerToken: string;

  constructor(
    readonly api: TestApi,
    readonly provider: ProviderSession,
    readonly customer: CustomerSession,
    readonly addressId: string,
  ) {
    this.providerToken = provider.token;
    this.customerToken = customer.token;
  }

  static async create(api: TestApi): Promise<World> {
    await seedCatalog(api);
    const p = await verifiedProvider(api, '01712345601', 'male', electrician);
    const online = await api.do('POST', '/v1/provider/presence/online', near, { token: p.token });
    if (online.status !== 200) {
      throw new Error(`online: ${online.text}`);
    }
    const c = await customer(api, '01812345602', 'bn');
    return new World(api, p, c.customer, c.addressId);
  }

  /** A booking request body, changed by `extra`. */
  body(extra: Record<string, unknown> = {}): Record<string, unknown> {
    return {
      providerId: this.provider.id,
      serviceId: electrician,
      timing: 'asap',
      addressId: this.addressId,
      items: [{ subServiceId: fan, quantity: 2 }],
      note: 'Second floor',
      ...extra,
    };
  }

  /** Posts a booking request with `key`. */
  request(key: string, extra?: Record<string, unknown>, token = this.customerToken) {
    const headers = { 'Idempotency-Key': key };
    return this.api.do('POST', '/v1/customer/bookings', this.body(extra), { token, headers });
  }

  /** Books and returns the id. */
  async book(key: string, extra?: Record<string, unknown>): Promise<string> {
    const r = await this.request(key, extra);
    if (r.status !== 201) {
      throw new Error(`book: ${String(r.status)} ${r.text}`);
    }
    return r.body?.id as string;
  }

  /** A provider action on a job. */
  job(id: string, action: string, body?: unknown) {
    return this.api.do('POST', `/v1/provider/jobs/${id}/${action}`, body, {
      token: this.providerToken,
    });
  }

  /** A customer call. */
  asCustomer(method: string, path: string, body?: unknown) {
    return this.api.do(method, path, body, { token: this.customerToken });
  }

  /** A provider call. */
  asProvider(method: string, path: string, body?: unknown) {
    return this.api.do(method, path, body, { token: this.providerToken });
  }

  /** The customer's start code. */
  async code(id: string): Promise<string> {
    const r = await this.asCustomer('GET', `/v1/customer/bookings/${id}/start-code`);
    return r.body?.code as string;
  }

  /** Accepts, travels, arrives and starts the job. */
  async run(id: string): Promise<void> {
    await this.job(id, 'accept');
    const code = await this.code(id);
    await this.job(id, 'on-the-way');
    await this.job(id, 'arrived');
    await this.job(id, 'start', { code });
  }

  /** Signs fresh tokens after the clock moved past the old ones' expiry. */
  async refreshTokens(): Promise<void> {
    this.providerToken = await this.api.token(this.provider.id, ['provider']);
    this.customerToken = await this.api.token(this.customer.id, ['customer']);
  }

  /** The nearby search path. */
  nearby(query: string): string {
    return `/v1/customer/providers/nearby?serviceId=${electrician}&subServiceId=${fan}&${query}`;
  }
}
