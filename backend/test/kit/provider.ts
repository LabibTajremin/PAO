// Provider helpers: a partner-app user enrolled through the
// API, and one a verifier approved to Level 1.
import { seedId } from '../../src/modules/catalog/app/seed-catalog';
import { type TestApi } from './api';
import { relayEvents } from './events';
import { adminSession, lastCode, signIn } from './identity';
import { upload } from './media';
import { deliver } from './events';
import { VerificationEvents } from '../../src/modules/verification/contract/events';

/** A spot in Banani where test providers go online. */
export const near = { location: { lat: 23.794, lng: 90.407 } };

/** A seeded catalog service's id, e.g. `service('electrician')`. */
export function service(key: string): string {
  return seedId('service', key);
}

/** An enrolled provider. */
export interface ProviderSession {
  readonly id: string;
  readonly token: string;
}

async function ok(api: TestApi, route: string, body: unknown, token: string) {
  const [method = '', path = ''] = route.split(' ');
  const r = await api.do(method, path, body, { token });
  if (r.status !== 200) {
    throw new Error(`${route}: ${String(r.status)} ${r.text}`);
  }
}

function profileSteps(gender: string, services: string[], contact: string) {
  return [
    {
      path: '/v1/provider/enrolment/personal',
      body: {
        fullName: 'Rahim Uddin',
        dateOfBirth: '1990-04-12',
        gender,
        presentAddress: 'House 12, Banani',
        permanentAddress: 'Cumilla Sadar',
      },
    },
    { path: '/v1/provider/enrolment/services', body: { serviceIds: services, experienceYears: 8 } },
    {
      path: '/v1/provider/enrolment/area',
      body: { homeBase: { lat: 23.7937, lng: 90.4066 }, workingRadiusM: 8000 },
    },
    {
      path: '/v1/provider/enrolment/code-of-conduct',
      body: { version: '2026-10', accepted: true },
    },
    {
      path: '/v1/provider/enrolment/emergency-contact',
      body: { name: 'Karim Uddin', relation: 'Brother', phone: contact },
    },
  ];
}

async function documentSteps(api: TestApi, p: ProviderSession, phone: string) {
  const file = (purpose: string) => upload(api, p.id, 'provider', purpose);
  const issued = new Date(api.clock.now());
  issued.setUTCMonth(issued.getUTCMonth() - 1);
  return [
    {
      path: '/v1/provider/enrolment/nid',
      body: {
        nidNumber: `1${phone.slice(-9)}`,
        frontMediaId: await file('nid_front'),
        backMediaId: await file('nid_back'),
      },
    },
    { path: '/v1/provider/enrolment/selfie', body: { mediaId: await file('selfie') } },
    {
      path: '/v1/provider/enrolment/police-clearance',
      body: {
        mediaId: await file('police_clearance'),
        issueDate: issued.toISOString().slice(0, 10),
      },
    },
  ];
}

/**
 * Signs a partner-app user in, completes every enrolment step with documents and submits
 * it. The emergency contact is `phone` with "019" in front of its last eight digits.
 */
export async function enrolledProvider(
  api: TestApi,
  phone: string,
  gender: string,
  ...services: string[]
): Promise<ProviderSession> {
  const tp = await signIn(api, phone, 'partner');
  const p = { id: tp.account.id, token: tp.accessToken };
  const contact = `019${phone.slice(-8)}`;
  const steps = [
    ...profileSteps(gender, services, contact),
    ...(await documentSteps(api, p, phone)),
  ];
  for (const s of steps) {
    await ok(api, `PUT ${s.path}`, s.body, p.token);
  }
  const code = lastCode(api, contact);
  await ok(api, 'POST /v1/provider/enrolment/emergency-contact/verify', { code }, p.token);
  await ok(api, 'POST /v1/provider/enrolment/submit', undefined, p.token);
  await relayEvents(api);
  return p;
}

/** Enrols a provider and has a verifier approve every submitted item: Level 1. */
export async function verifiedProvider(
  api: TestApi,
  phone: string,
  gender: string,
  ...services: string[]
): Promise<ProviderSession> {
  const p = await enrolledProvider(api, phone, gender, ...services);
  const verifier = (await adminSession(api, ['verifier'])).accessToken;
  const items = ['nid', 'selfie', 'police_clearance', 'address', 'emergency_contact'];
  for (const item of [...items, 'service_area', 'code_of_conduct']) {
    const path = `/v1/admin/verifications/${p.id}/items/${item}/approve`;
    await ok(api, `POST ${path}`, undefined, verifier);
  }
  await relayEvents(api);
  return p;
}

/** The personal step of a test provider. */
export function personal(gender: string): Record<string, string> {
  return {
    fullName: 'Rahim Uddin',
    dateOfBirth: '1990-04-12',
    gender,
    presentAddress: 'House 12, Banani',
    permanentAddress: 'Cumilla Sadar',
    bio: 'Electrician',
  };
}

/** Completes every profile step for a new partner-app user. */
export async function enrol(api: TestApi, phone: string, gender: string, ...services: string[]) {
  const tp = await signIn(api, phone, 'partner');
  const steps: [string, unknown][] = [
    ['/v1/provider/enrolment/personal', personal(gender)],
    ['/v1/provider/enrolment/services', { serviceIds: services, experienceYears: 8 }],
    [
      '/v1/provider/enrolment/area',
      { homeBase: { lat: 23.7937, lng: 90.4066 }, workingRadiusM: 8000 },
    ],
    ['/v1/provider/enrolment/code-of-conduct', { version: '2026-10', accepted: true }],
  ];
  for (const [path, body] of steps) {
    const r = await api.do('PUT', path, body, { token: tp.accessToken });
    if (r.status !== 200) {
      throw new Error(`${path}: ${String(r.status)} ${r.text}`);
    }
  }
  return { id: tp.account.id, token: tp.accessToken };
}

/** Enrols a provider, sets their level and puts them online. */
export async function online(
  api: TestApi,
  who: { phone: string; gender: string; level: number },
  ...services: string[]
) {
  const { phone, gender, level } = who;
  const p = await enrol(api, phone, gender, ...services);
  await deliver(api, {
    name: VerificationEvents.ProviderLevelChanged,
    providerId: p.id,
    from: 0,
    to: level,
    reason: 'review',
  } as never);
  const r = await api.do('POST', '/v1/provider/presence/online', near, { token: p.token });
  if (r.status !== 200) {
    throw new Error(`online: ${String(r.status)} ${r.text}`);
  }
  return p;
}
