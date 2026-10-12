import { customer, phoneFor } from './support/actors';
import { eventually, get } from './support/client';
import {
  addDate,
  approve,
  enrolledProvider,
  goOnline,
  items,
  nearby,
  service,
  tryOnline,
} from './support/provider';

test('onboarding: enrol, approve, go online and be found', async () => {
  const c = await customer(phoneFor('017', 1));
  const svc = await service(c, 'Electrician');
  const p = await enrolledProvider(phoneFor('018', 2), svc.id, addDate(new Date(), 0, -1, 0));
  expect(await tryOnline(p)).not.toBe(200);

  await approve(p, ...items);
  const status = (await get('/v1/provider/verification', p)).expect(200);
  expect(status).toMatchObject({ level: 1, canReceiveBookings: true });

  await goOnline(p);
  await eventually(10_000, 'provider in nearby search', () =>
    nearby(c, svc.id, svc.sub, String(p.id)),
  );
});
