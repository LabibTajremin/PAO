import { customer, phoneFor, requestCode } from './support/actors';
import { admin } from './support/admins';
import { onlineProvider } from './support/booking';
import { eventually, get, send, type Session } from './support/client';
import { obj } from './support/json';
import { nearby, service } from './support/provider';

// Waits for the ban to reach identity (the worker relays it), then checks the old
// access token is refused and the phone cannot ask for a login code.
async function expectLockedOut(s: Session, phone: string, path: string): Promise<void> {
  await eventually(10_000, 'session revoked', async () => (await get(path, s)).status === 401);
  await eventually(10_000, 'sign-in refused', async () => {
    const r = await requestCode(phone);
    if (r.status === 202) throw new Error('a banned phone was sent a login code');
    return r.status === 403 && r.code() === 'ACCOUNT_BANNED';
  });
}

test('ban: provider loses sessions, search and sign-in', async () => {
  const c = await customer(phoneFor('017', 41));
  const svc = await service(c, 'Electrician');
  const p = await onlineProvider(42, svc.id);
  await eventually(10_000, 'provider in nearby search', () => nearby(c, svc.id, svc.sub, p.id));

  const ban = { status: 'banned', reason: 'Fraudulent documents' };
  const root = await admin('super@pao.bd');
  const banned = (await send('POST', `/v1/admin/providers/${p.id}/status`, ban, root)).expect(200);
  expect(obj(banned.summary).status).toBe('banned');

  await expectLockedOut(p.session, p.phone, '/v1/provider/profile');
  await eventually(10_000, 'banned provider hidden from search', async () => {
    return !(await nearby(c, svc.id, svc.sub, p.id));
  });
});

test('ban: customer loses sessions and sign-in', async () => {
  const phone = phoneFor('017', 43);
  const c = await customer(phone);
  (await get('/v1/customer/profile', c)).expect(200);
  const root = await admin('super@pao.bd');
  const path = `/v1/admin/customers/${String(c.id)}/status`;

  expect((await send('POST', path, { status: 'banned' }, root)).status).toBe(422);
  (await send('POST', path, { status: 'banned', reason: 'Abused providers' }, root)).expect(200);
  await expectLockedOut(c, phone, '/v1/customer/profile');
});
