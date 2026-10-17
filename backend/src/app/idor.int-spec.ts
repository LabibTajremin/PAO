// Insecure direct object references (ASVS V4.2.1): every customer and provider route
// with a path id is called by another account of the same role, which must learn
// nothing — 404 or 403, never the owner's data or a state error that confirms the id.
import { startTestApi, type TestApi } from '../../test/kit/api';
import { completedJob, customer } from '../../test/kit/booking';
import { World, fan } from '../../test/kit/booking-world';
import { relayEvents } from '../../test/kit/events';
import { upload } from '../../test/kit/media';
import { verifiedProvider } from '../../test/kit/provider';
import { OPENAPI_DOCUMENT, type OpenApiDocument } from '../platform/http/spec-routes';

const METHODS = ['get', 'put', 'post', 'patch', 'delete'];

// Path ids that name public records (the catalog, provider profiles), not owned ones.
const PUBLIC_IDS = ['{serviceId}', '{providerId}'];

/** The owned resources the cases point at. */
interface Owned {
  readonly address: string;
  readonly booking: string;
  readonly completed: string;
  readonly customerNote: string;
  readonly providerNote: string;
  readonly customerUpload: string;
  readonly providerUpload: string;
}

type Case = readonly [route: string, path: (o: Owned) => string, body?: unknown];

const proposal = '0190f3a0-0000-7000-8000-000000000001';
const address = {
  label: 'home',
  line1: 'House 1',
  area: 'Gulshan',
  location: { lat: 23.79, lng: 90.41 },
};
const report = { reason: 'late', description: 'Arrived two hours late.' };

const customerCases: Case[] = [
  ['PUT /v1/customer/addresses/{addressId}', (o) => `/v1/customer/addresses/${o.address}`, address],
  ['DELETE /v1/customer/addresses/{addressId}', (o) => `/v1/customer/addresses/${o.address}`],
  [
    'POST /v1/customer/addresses/{addressId}/default',
    (o) => `/v1/customer/addresses/${o.address}/default`,
  ],
  ['GET /v1/customer/bookings/{bookingId}', (o) => `/v1/customer/bookings/${o.booking}`],
  [
    'GET /v1/customer/bookings/{bookingId}/start-code',
    (o) => `/v1/customer/bookings/${o.booking}/start-code`,
  ],
  [
    'POST /v1/customer/bookings/{bookingId}/cancel',
    (o) => `/v1/customer/bookings/${o.booking}/cancel`,
    { reason: 'other' },
  ],
  [
    'POST /v1/customer/bookings/{bookingId}/extras/decision',
    (o) => `/v1/customer/bookings/${o.booking}/extras/decision`,
    { proposalId: proposal, approve: true },
  ],
  [
    'GET /v1/customer/bookings/{bookingId}/receipt',
    (o) => `/v1/customer/bookings/${o.booking}/receipt`,
  ],
  [
    'POST /v1/customer/bookings/{bookingId}/review',
    (o) => `/v1/customer/bookings/${o.completed}/review`,
    { stars: 5 },
  ],
  [
    'POST /v1/customer/bookings/{bookingId}/reports',
    (o) => `/v1/customer/bookings/${o.booking}/reports`,
    report,
  ],
  [
    'POST /v1/customer/notifications/{notificationId}/read',
    (o) => `/v1/customer/notifications/${o.customerNote}/read`,
  ],
  [
    'POST /v1/customer/uploads/{mediaId}/confirm',
    (o) => `/v1/customer/uploads/${o.customerUpload}/confirm`,
  ],
];

const job = (action: string, body?: unknown): Case => [
  `POST /v1/provider/jobs/{bookingId}/${action}`,
  (o) => `/v1/provider/jobs/${o.booking}/${action}`,
  body,
];

const providerCases: Case[] = [
  ['GET /v1/provider/jobs/{bookingId}', (o) => `/v1/provider/jobs/${o.booking}`],
  job('accept'),
  job('reject', { reason: 'busy' }),
  job('on-the-way'),
  job('arrived'),
  job('start', { code: '1234' }),
  job('extras', { items: [{ subServiceId: fan, quantity: 1 }] }),
  job('complete', { cashReceived: true }),
  job('cancel', { reason: 'emergency' }),
  [
    'POST /v1/provider/jobs/{bookingId}/review',
    (o) => `/v1/provider/jobs/${o.completed}/review`,
    { stars: 4 },
  ],
  job('reports', report),
  ['GET /v1/provider/jobs/{bookingId}/receipt', (o) => `/v1/provider/jobs/${o.booking}/receipt`],
  [
    'POST /v1/provider/notifications/{notificationId}/read',
    (o) => `/v1/provider/notifications/${o.providerNote}/read`,
  ],
  [
    'POST /v1/provider/uploads/{mediaId}/confirm',
    (o) => `/v1/provider/uploads/${o.providerUpload}/confirm`,
  ],
];

// Reviews answer one conflict for any booking the caller may not review — unknown,
// unfinished or someone else's — so the answer confirms nothing either.
const UNIFORM_CONFLICT = new Set([
  'POST /v1/customer/bookings/{bookingId}/review',
  'POST /v1/provider/jobs/{bookingId}/review',
]);

/** Every customer or provider operation whose path holds an owned id, per the contract. */
function ownedRoutes(doc: OpenApiDocument): string[] {
  const routes: string[] = [];
  for (const [path, item] of Object.entries(doc.paths)) {
    const scoped = /^\/v1\/(customer|provider)\//.test(path) && path.includes('{');
    if (!scoped || PUBLIC_IDS.some((id) => path.includes(id))) {
      continue;
    }
    for (const method of METHODS.filter((m) => m in (item as object))) {
      routes.push(`${method.toUpperCase()} ${path}`);
    }
  }
  return routes.sort();
}

async function firstNotification(api: TestApi, side: string, token: string): Promise<string> {
  const r = await api.do('GET', `/v1/${side}/notifications`, undefined, { token });
  const items = r.body?.items as { id: string }[];
  if (items.length === 0) {
    throw new Error(`no ${side} notification`);
  }
  return items[0]!.id;
}

describe('object-level authorisation', () => {
  let api: TestApi;
  let owned: Owned;
  let otherCustomer: string;
  let otherProvider: string;
  let world: World;

  beforeAll(async () => {
    api = await startTestApi();
    const done = await completedJob(api, '01712345697', '01812345696');
    const w = (world = await World.create(api));
    const booking = await w.book('idor-booking');
    await w.job(booking, 'accept');
    await relayEvents(api);
    owned = {
      address: w.addressId,
      booking,
      completed: done.id,
      customerNote: await firstNotification(api, 'customer', w.customerToken),
      providerNote: await firstNotification(api, 'provider', w.providerToken),
      customerUpload: await upload(api, w.customer.id, 'customer', 'avatar'),
      providerUpload: await upload(api, w.provider.id, 'provider', 'avatar'),
    };
    otherCustomer = (await customer(api, '01812345699')).customer.token;
    otherProvider = (
      await verifiedProvider(api, '01712345698', 'male', w.body().serviceId as string)
    ).token;
  });

  it('lets the owners themselves read the same ids', async () => {
    const mine = await world.asCustomer('GET', `/v1/customer/bookings/${owned.booking}`);
    const job = await world.asProvider('GET', `/v1/provider/jobs/${owned.booking}`);
    expect([mine.status, job.status]).toEqual([200, 200]);
  });

  it('has a case for every owned-id route in the contract', () => {
    const covered = [...customerCases, ...providerCases].map(([route]) => route).sort();
    expect(covered).toEqual(ownedRoutes(api.app.get(OPENAPI_DOCUMENT)));
  });

  it.each([
    // Four fields in every row: a shorter one would make Jest pass `done` as the body.
    ...customerCases.map(([route, path, body]) => ['customer', route, path, body] as const),
    ...providerCases.map(([route, path, body]) => ['provider', route, path, body] as const),
  ])('a different %s gets nothing from %s', async (role, route, path, body) => {
    const method = route.split(' ')[0]!;
    const token = role === 'customer' ? otherCustomer : otherProvider;
    const headers = { 'Idempotency-Key': `idor-${route}` };
    const r = await api.do(method, path(owned), body, { token, headers });
    if (UNIFORM_CONFLICT.has(route)) {
      expect(r).toMatchObject({ status: 409, code: 'REVIEW_NOT_ALLOWED' });
    } else {
      expect([403, 404]).toContain(r.status);
    }
  });
});
