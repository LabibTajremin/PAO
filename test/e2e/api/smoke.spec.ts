import { customer, phoneFor } from './support/actors';
import { call, get } from './support/client';
import { list } from './support/json';
import { catalogService } from './support/provider';
import { stack } from './support/stack';

// The composition roots work: the api and worker processes started and are ready, and
// migrate migrated and seeded the database. Unit coverage excludes those entry points,
// so the stack is their test.
test('smoke: services start and are ready', async () => {
  const probes = [
    [stack().api, '/healthz'],
    [stack().api, '/readyz'],
    [stack().worker, '/healthz'],
  ] as const;
  for (const [base, path] of probes) {
    const r = await call(base, { method: 'GET', path });
    expect({ probe: base + path, status: r.status }).toEqual({ probe: base + path, status: 200 });
  }
  const c = await customer(phoneFor('017', 71));
  const tree = (await get('/v1/customer/catalog', c)).expect(200);
  expect(list(tree.categories).length).toBeGreaterThan(0);
  const electrician = await catalogService(c, 'Electrician');
  expect(electrician.subs.length).toBeGreaterThan(0);
  expect(electrician.subs[0]?.price).toBeGreaterThan(0);
});
