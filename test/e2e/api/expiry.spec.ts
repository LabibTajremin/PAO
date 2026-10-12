import { customer, phoneFor, upload } from './support/actors';
import { onCleanup } from './support/cleanup';
import { eventually, get, send, type Session } from './support/client';
import { list, type Json } from './support/json';
import {
  addDate,
  approve,
  dateOnly,
  enrolledProvider,
  goOnline,
  items,
  nearby,
  service,
  tryOnline,
} from './support/provider';

function itemStatus(status: Json, item: string): unknown {
  return list(status.items).find((it) => it.type === item)?.status ?? '';
}

async function verification(p: Session): Promise<Json> {
  return (await get('/v1/provider/verification', p)).expect(200);
}

test('expiry: police clearance lapses, then a renewal restores the provider', async () => {
  const c = await customer(phoneFor('017', 31));
  const svc = await service(c, 'Electrician');
  // Issued a day short of the validity period, so it lapses tomorrow; every other
  // journey's clearance is a month old and stays valid past the sweep below.
  const p = await enrolledProvider(phoneFor('018', 32), svc.id, addDate(new Date(), 0, 0, -364));
  const found = () => nearby(c, svc.id, svc.sub, String(p.id));
  await approve(p, ...items);
  await goOnline(p);
  onCleanup(() => send('POST', '/v1/provider/presence/offline', undefined, p));
  await eventually(10_000, 'provider in nearby search', found);

  const sweepAt = addDate(new Date(), 0, 0, 3)
    .toISOString()
    .replace(/\.\d{3}Z$/, 'Z');
  const sweep = await send(
    'POST',
    `/__test/verification/expire?at=${encodeURIComponent(sweepAt)}`,
    undefined,
  );
  expect(sweep.status).toBe(204);
  const lapsed = await verification(p);
  expect(lapsed).toMatchObject({ level: 0, canReceiveBookings: false });
  expect(itemStatus(lapsed, 'police_clearance')).toBe('expired');
  await eventually(10_000, 'provider hidden from search', async () => !(await found()));
  expect(await tryOnline(p)).not.toBe(200);

  const renewed = {
    mediaId: await upload(p, 'provider', 'police_clearance'),
    issueDate: dateOnly(addDate(new Date(), 0, 0, -7)),
  };
  (await send('PUT', '/v1/provider/enrolment/police-clearance', renewed, p)).expect(200);
  expect(itemStatus(await verification(p), 'police_clearance')).toBe('pending');
  await approve(p, 'police_clearance');
  expect(await verification(p)).toMatchObject({ level: 1, canReceiveBookings: true });
  await goOnline(p);
  await eventually(10_000, 'provider back in nearby search', found);
});
