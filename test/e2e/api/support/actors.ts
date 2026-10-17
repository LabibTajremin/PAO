import { get, send, type Reply, type Session } from './client';
import { obj, str } from './json';

/** The newest one-time code texted to `phone`, read from the SMS capture. */
export async function lastCode(phone: string): Promise<string> {
  const r = await get(`/__test/sms?phone=${encodeURIComponent(phone)}`);
  if (r.status !== 200) throw new Error(`no sms to ${phone}: ${r.status}`);
  return /[0-9]{6}/.exec(str(r.json().message))?.[0] ?? '';
}

function fnv32a(text: string): number {
  let hash = 0x811c9dc5;
  for (const byte of Buffer.from(text)) {
    hash = Math.imul(hash ^ byte, 0x01000193) >>> 0;
  }
  return hash;
}

/** The address `phone`'s device connects from, stable per phone. */
export function deviceOf(phone: string): Session {
  const n = fnv32a(phone);
  return { ip: `198.18.${(n >>> 8) & 0xff}.${n & 0xff}` };
}

/** Asks for a login code from `phone`'s device. */
export function requestCode(phone: string): Promise<Reply> {
  return send('POST', '/v1/auth/otp/request', { phone, purpose: 'login' }, deviceOf(phone));
}

/** Requests and enters a one-time code; `app` is "customer" or "partner". */
export async function signIn(phone: string, app: 'customer' | 'partner'): Promise<Session> {
  const r = await requestCode(phone);
  if (r.status !== 202) throw new Error(`code for ${phone}: ${r.status} ${r.body}`);
  const device = deviceOf(phone);
  const code = await lastCode(phone);
  const tokens = (await send('POST', '/v1/auth/otp/verify', { phone, code, app }, device)).expect(
    200,
  );
  return { id: str(obj(tokens.account).id), token: str(tokens.accessToken), ip: device.ip };
}

/** A new customer and the ID of their default address, for bookings. */
export interface Customer {
  readonly session: Session;
  readonly address: string;
}

/** Signs a new customer up with a profile and a default address in Banani. */
export async function customerAt(phone: string): Promise<Customer> {
  const c = await signIn(phone, 'customer');
  const profile = { name: 'Nusrat Jahan', language: 'en' };
  (await send('PUT', '/v1/customer/profile', profile, c)).expect(200);
  const home = {
    label: 'home',
    line1: 'House 12, Road 5, Banani',
    location: { lat: 23.794, lng: 90.407 },
    isDefault: true,
  };
  const address = (await send('POST', '/v1/customer/addresses', home, c)).expect(201);
  return { session: c, address: str(address.id) };
}

/** `customerAt` without the address. */
export async function customer(phone: string): Promise<Session> {
  return (await customerAt(phone)).session;
}

/**
 * Stores a small confirmed image through the signed URL, as an app would; `role` is
 * "customer" or "provider". Returns the media ID.
 */
export async function upload(s: Session, role: string, purpose: string): Promise<string> {
  const body = Buffer.from('e2e-image');
  const ticket = (
    await send(
      'POST',
      `/v1/${role}/uploads`,
      { purpose, contentType: 'image/jpeg', sizeBytes: body.length },
      s,
    )
  ).expect(201);
  const headers = Object.fromEntries(
    Object.entries(obj(ticket.headers)).map(([k, v]) => [k, str(v)]),
  );
  const res = await fetch(str(ticket.uploadUrl), { method: 'PUT', headers, body });
  if (res.status !== 200) throw new Error(`put ${purpose}: ${res.status} ${await res.text()}`);
  const id = str(ticket.mediaId);
  (await send('POST', `/v1/${role}/uploads/${id}/confirm`, undefined, s)).expect(200);
  return id;
}

/** Gives each test its own Bangladeshi mobile number. */
export function phoneFor(prefix: string, n: number): string {
  const micros = BigInt(Date.now()) * 1000n + ((process.hrtime.bigint() / 1000n) % 1000n);
  const tail = (micros + BigInt(n)) % 100_000_000n;
  return prefix + tail.toString().padStart(8, '0');
}
