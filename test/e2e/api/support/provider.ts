import { lastCode, signIn, upload } from './actors';
import { admin } from './admins';
import { eventually, get, send, type Session } from './client';
import { list, obj, str } from './json';

/** Where every e2e provider works and every e2e customer lives. */
export const banani = { lat: 23.7937, lng: 90.4066 };

/** The Level 1 verification items a verifier approves. */
export const items = [
  'nid',
  'selfie',
  'police_clearance',
  'address',
  'emergency_contact',
  'service_area',
  'code_of_conduct',
];

/** A sub-service with its current price in paisa. */
export interface Sub {
  readonly id: string;
  readonly price: number;
}

/** A seeded service with its sub-services in catalog order. */
export interface Offer {
  readonly id: string;
  readonly subs: Sub[];
}

/** Finds a seeded service by English name in the customer catalog. */
export async function catalogService(s: Session, name: string): Promise<Offer> {
  const tree = (await get('/v1/customer/catalog', s)).expect(200);
  for (const category of list(tree.categories)) {
    const found = list(category.services).find((svc) => obj(svc.name).en === name);
    if (found) {
      const subs = list(found.subServices).map((it) => ({
        id: str(it.id),
        price: Number(it.price),
      }));
      return { id: str(found.id), subs };
    }
  }
  throw new Error(`no service ${JSON.stringify(name)}`);
}

/** A seeded service's ID and the ID of its first sub-service. */
export async function service(s: Session, name: string): Promise<{ id: string; sub: string }> {
  const offer = await catalogService(s, name);
  return { id: offer.id, sub: firstSub(offer).id };
}

/** The first sub-service of an offer. */
export function firstSub(offer: Offer): Sub {
  const sub = offer.subs[0];
  if (sub === undefined) throw new Error(`service ${offer.id} has no sub-services`);
  return sub;
}

/** A calendar date as the API takes it, YYYY-MM-DD. */
export function dateOnly(at: Date): string {
  return at.toISOString().slice(0, 10);
}

/** `at` moved by whole days, months and years. */
export function addDate(at: Date, years: number, months: number, days: number): Date {
  const d = new Date(at);
  d.setFullYear(d.getFullYear() + years, d.getMonth() + months, d.getDate() + days);
  return d;
}

async function enrolmentSteps(p: Session, phone: string, serviceId: string, policeIssued: Date) {
  const contact = '019' + phone.slice(-8);
  return [
    [
      'personal',
      {
        fullName: 'Rahim Uddin',
        dateOfBirth: '1990-04-12',
        gender: 'male',
        presentAddress: 'House 12, Banani',
        permanentAddress: 'Cumilla Sadar',
      },
    ],
    ['services', { serviceIds: [serviceId], experienceYears: 8 }],
    ['area', { homeBase: banani, workingRadiusM: 8000 }],
    ['code-of-conduct', { version: '2026-10', accepted: true }],
    ['emergency-contact', { name: 'Karim Uddin', relation: 'Brother', phone: contact }],
    [
      'nid',
      {
        nidNumber: '1' + phone.slice(-9),
        frontMediaId: await upload(p, 'provider', 'nid_front'),
        backMediaId: await upload(p, 'provider', 'nid_back'),
      },
    ],
    ['selfie', { mediaId: await upload(p, 'provider', 'selfie') }],
    [
      'police-clearance',
      {
        mediaId: await upload(p, 'provider', 'police_clearance'),
        issueDate: dateOnly(policeIssued),
      },
    ],
  ] as const;
}

/**
 * Signs a partner-app user in, completes every enrolment step with documents and
 * submits it; `policeIssued` dates the police clearance.
 */
export async function enrolledProvider(
  phone: string,
  serviceId: string,
  policeIssued: Date,
): Promise<Session> {
  const p = await signIn(phone, 'partner');
  for (const [step, body] of await enrolmentSteps(p, phone, serviceId, policeIssued)) {
    (await send('PUT', `/v1/provider/enrolment/${step}`, body, p)).expect(200);
  }
  const code = await lastCode('019' + phone.slice(-8));
  (await send('POST', '/v1/provider/enrolment/emergency-contact/verify', { code }, p)).expect(200);
  (await send('POST', '/v1/provider/enrolment/submit', undefined, p)).expect(200);
  return p;
}

/**
 * Has the seeded verifier approve each item of `p`'s submission, once the worker has
 * relayed the submission and every item waits for review.
 */
export async function approve(p: Session, ...which: string[]): Promise<void> {
  const v = await admin('verifier@pao.bd');
  await eventually(10_000, 'items pending review', async () => {
    const status = (await get(`/v1/admin/verifications/${String(p.id)}`, v)).expect(200);
    const pending = new Set(
      list(status.items)
        .filter((it) => it.status === 'pending')
        .map((it) => it.type),
    );
    return which.every((item) => pending.has(item));
  });
  for (const item of which) {
    const path = `/v1/admin/verifications/${String(p.id)}/items/${item}/approve`;
    // One verifier approves every provider of the suite; back-to-back runs can pass the
    // per-user limit of 120 calls a minute, so wait for the window to slide.
    await eventually(70_000, 'approval within the rate limit', async () => {
      const r = await send('POST', path, undefined, v);
      if (r.status !== 200 && r.status !== 429) {
        throw new Error(`POST ${path}: ${r.status} ${r.body}`);
      }
      return r.status === 200;
    });
  }
}

/** Brings `p` online in Banani; the status of the call is returned, not checked. */
export async function tryOnline(p: Session): Promise<number> {
  return (await send('POST', '/v1/provider/presence/online', { location: banani }, p)).status;
}

/**
 * Waits for the approved level to reach the provider module (the worker relays it),
 * then brings the provider online in Banani.
 */
export async function goOnline(p: Session): Promise<void> {
  await eventually(10_000, 'provider allowed online', async () => (await tryOnline(p)) === 200);
}

/**
 * Reports whether customer `c` finds provider `providerId` for the sub-service, reading
 * every page: providers of earlier runs may still be online at the same spot.
 */
export async function nearby(
  c: Session,
  serviceId: string,
  subServiceId: string,
  providerId: string,
): Promise<boolean> {
  const q =
    `/v1/customer/providers/nearby?serviceId=${serviceId}&subServiceId=${subServiceId}` +
    `&quantity=1&lat=${banani.lat}&lng=${banani.lng}`;
  for (let page = q; ;) {
    const res = (await get(page, c)).expect(200);
    if (list(res.items).some((it) => it.id === providerId)) return true;
    const next = typeof res.nextCursor === 'string' ? res.nextCursor : '';
    if (next === '') return false;
    page = `${q}&cursor=${encodeURIComponent(next)}`;
  }
}
