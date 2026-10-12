import { customer, phoneFor } from './support/actors';
import { admin } from './support/admins';
import { get, send } from './support/client';

// Seeded admins and the role each holds (docs/build/02-architecture.md §6).
const root = 'super@pao.bd';
const verifier = 'verifier@pao.bd';
const catalog = 'catalog@pao.bd';
const support = 'support@pao.bd';

const missing = '00000000-0000-4000-8000-000000000000';
const probeReason = { reason: 'RBAC probe' };

// One representative endpoint per admin permission. Probes that would change something
// name an ID or key that does not exist, so a permitted call stops at 404 after the
// permission check and a forbidden one at 403 before it.
const probes: [string, string, string, unknown, number, string[]][] = [
  [
    'dashboard:read',
    'GET',
    '/v1/admin/dashboard',
    undefined,
    200,
    [root, verifier, catalog, support],
  ],
  ['catalog:manage', 'GET', '/v1/admin/catalog', undefined, 200, [root, catalog]],
  ['settings:read', 'GET', '/v1/admin/settings', undefined, 200, [root, catalog]],
  ['settings:manage', 'PUT', '/v1/admin/settings/no.such.setting', { value: '1' }, 404, [root]],
  ['verification:review', 'GET', '/v1/admin/verifications', undefined, 200, [root, verifier]],
  [
    'verification:docs:view',
    'GET',
    `/v1/admin/documents/${missing}/view-url`,
    undefined,
    404,
    [root, verifier],
  ],
  ['level2:manage', 'GET', '/v1/admin/level2-sessions', undefined, 200, [root, verifier]],
  ['provider:read', 'GET', '/v1/admin/providers', undefined, 200, [root, verifier, support]],
  [
    'provider:manage',
    'POST',
    `/v1/admin/providers/${missing}/status`,
    { status: 'suspended', ...probeReason },
    404,
    [root],
  ],
  ['customer:read', 'GET', '/v1/admin/customers', undefined, 200, [root, support]],
  [
    'customer:manage',
    'POST',
    `/v1/admin/customers/${missing}/status`,
    { status: 'suspended', ...probeReason },
    404,
    [root],
  ],
  ['booking:read:any', 'GET', '/v1/admin/bookings', undefined, 200, [root, support]],
  ['complaint:manage', 'GET', '/v1/admin/complaints', undefined, 200, [root, support]],
  ['audit:read', 'GET', '/v1/admin/audit', undefined, 200, [root]],
  ['admin_user:manage', 'GET', '/v1/admin/admin-users', undefined, 200, [root]],
  ['role:manage', 'GET', '/v1/admin/roles', undefined, 200, [root]],
];

test('rbac: each admin role reaches only its endpoints', async () => {
  const mismatches: string[] = [];
  for (const email of [root, verifier, catalog, support]) {
    const s = await admin(email);
    for (const [permission, method, path, body, permittedCode, roles] of probes) {
      const want = roles.includes(email) ? permittedCode : 403;
      const r = await send(method, path, body, s);
      if (r.status !== want) {
        mismatches.push(
          `${email} ${method} ${path} (${permission}): want ${want}, got ${r.status} ${r.body}`,
        );
      }
      if (want === 403 && r.code() !== 'FORBIDDEN') {
        mismatches.push(`${email} ${path}: error code ${JSON.stringify(r.code())}`);
      }
    }
  }
  expect(mismatches).toEqual([]);
});

test('rbac: app users cannot reach the admin API', async () => {
  const c = await customer(phoneFor('017', 51));
  const mismatches: string[] = [];
  for (const [, method, path, body] of probes) {
    const r = await send(method, path, body, c);
    if (r.status !== 403) mismatches.push(`customer ${method} ${path}: ${r.status}`);
  }
  const anonymous = await get('/v1/admin/dashboard');
  if (anonymous.status !== 401) mismatches.push(`anonymous dashboard: ${anonymous.status}`);
  expect(mismatches).toEqual([]);
});
