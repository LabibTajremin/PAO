import { phoneFor } from './actors';
import { admin } from './admins';
import { onCleanup } from './cleanup';
import { call, get, send, type Reply, type Session } from './client';
import { list, str, type Json } from './json';
import { addDate, approve, enrolledProvider, goOnline, items, type Sub } from './provider';
import { stack } from './stack';

/** An approved, online provider whose phone registered a push token. */
export interface Partner {
  readonly session: Session;
  readonly id: string;
  readonly phone: string;
  readonly pushToken: string;
}

/**
 * Enrols a provider for `serviceId`, has every item approved, registers a device for
 * pushes and brings them online; they go offline when the test ends so later runs do
 * not page through them in nearby search.
 */
export async function onlineProvider(n: number, serviceId: string): Promise<Partner> {
  const phone = phoneFor('018', n);
  const session = await enrolledProvider(phone, serviceId, addDate(new Date(), 0, -1, 0));
  await approve(session, ...items);
  const pushToken = `e2e-push-${phone}-${process.hrtime.bigint()}`;
  const device = { token: pushToken, platform: 'android' };
  (await send('PUT', '/v1/provider/device-token', device, session)).expect(204);
  await goOnline(session);
  onCleanup(() => send('POST', '/v1/provider/presence/offline', undefined, session));
  return { session, id: String(session.id), phone, pushToken };
}

/** One item of a booking request. */
export interface Line {
  readonly sub: Sub;
  readonly quantity: number;
}

/** The request body for booking lines. */
export function lines(...ls: Line[]): Json[] {
  return ls.map((l) => ({ subServiceId: l.sub.id, quantity: l.quantity }));
}

/** Who books what, where. */
export interface Order {
  readonly customer: Session;
  readonly address: string;
  readonly providerId: string;
  readonly serviceId: string;
}

/**
 * Has the customer request an ASAP booking with the provider at the address, with a
 * fresh idempotency key, and returns the created booking.
 */
export async function bookASAP(order: Order, ...ls: Line[]): Promise<Json> {
  const c = order.customer;
  const body = {
    providerId: order.providerId,
    serviceId: order.serviceId,
    timing: 'asap',
    addressId: order.address,
    items: lines(...ls),
    note: 'Second floor',
  };
  const key = `e2e-${String(c.id)}-${process.hrtime.bigint()}`;
  const r = await call(stack().api, {
    method: 'POST',
    path: '/v1/customer/bookings',
    body,
    as: c,
    headers: { 'Idempotency-Key': key },
  });
  const b = r.expect(201);
  if (b.status !== 'requested') throw new Error(`new booking: ${r.body}`);
  return b;
}

/** Sends a provider action ("accept", "on-the-way", "start", ...) on a booking. */
export function job(p: Partner, bookingId: string, action: string, body?: unknown): Promise<Reply> {
  return send('POST', `/v1/provider/jobs/${bookingId}/${action}`, body, p.session);
}

/** `job` that fails unless the action succeeds, returning the booking. */
export async function mustJob(
  p: Partner,
  bookingId: string,
  action: string,
  body?: unknown,
): Promise<Json> {
  return (await job(p, bookingId, action, body)).expect(200);
}

/** The code the customer reads out to the provider on arrival. */
export async function startCode(c: Session, bookingId: string): Promise<string> {
  return str((await get(`/v1/customer/bookings/${bookingId}/start-code`, c)).expect(200).code);
}

/** Takes an accepted booking to in_progress with the customer's start code. */
export async function startJob(c: Session, p: Partner, bookingId: string): Promise<void> {
  const code = await startCode(c, bookingId);
  await mustJob(p, bookingId, 'on-the-way');
  await mustJob(p, bookingId, 'arrived');
  const b = await mustJob(p, bookingId, 'start', { code });
  if (b.status !== 'in_progress') throw new Error(`start: ${JSON.stringify(b)}`);
}

/** The booking status the customer sees. */
export async function customerStatus(c: Session, bookingId: string): Promise<string> {
  return str((await get(`/v1/customer/bookings/${bookingId}`, c)).expect(200).status);
}

/** Whether the worker sent a push of the template about the booking to the token. */
export async function pushed(token: string, template: string, bookingId: string): Promise<boolean> {
  const r = await call(stack().worker, {
    method: 'GET',
    path: `/__test/pushes?token=${encodeURIComponent(token)}`,
  });
  return list(r.expect(200).pushes).some((p) => {
    const data = typeof p.data === 'object' && p.data !== null ? (p.data as Json) : {};
    return data.type === template && data.bookingId === bookingId;
  });
}

/**
 * Changes an admin setting as the super admin and restores the old value when the test
 * ends, so a failing test cannot leave the stack reconfigured.
 */
export async function setSetting(key: string, value: string): Promise<void> {
  const root = await admin('super@pao.bd');
  const settings = list((await get('/v1/admin/settings', root)).expect(200).items);
  const old = settings.find((s) => s.key === key)?.value;
  if (typeof old !== 'string' || old === '') throw new Error(`no setting ${key}`);
  const put = async (v: string) =>
    (await send('PUT', `/v1/admin/settings/${key}`, { value: v }, root)).expect(200);
  await put(value);
  onCleanup(() => put(old));
}
