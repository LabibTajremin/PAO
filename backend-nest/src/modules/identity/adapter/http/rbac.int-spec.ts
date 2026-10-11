import { randomUUID } from 'node:crypto';
import { startTestApi, type TestApi } from '../../../../../test/kit/api';
import { DATABASE, type Database } from '../../../../platform/db/database';
import { OPENAPI_DOCUMENT, type OpenApiDocument } from '../../../../platform/http/spec-routes';

interface Operation {
  readonly method: string;
  readonly path: string;
  readonly permission: string;
}

const METHODS = ['get', 'post', 'put', 'patch', 'delete'];

/** Every operation that needs a permission, with sample path parameters. */
function protectedOperations(doc: OpenApiDocument): Operation[] {
  const paths = (doc as unknown as { paths: Record<string, Record<string, unknown>> }).paths;
  const fill = (path: string) =>
    path
      .replace('{role}', 'customer')
      .replace('{itemType}', 'nid')
      .replace('{key}', 'booking.accept_timeout_asap_seconds')
      .replace(/\{[a-zA-Z]+\}/g, () => randomUUID());
  return Object.entries(paths).flatMap(([path, ops]) =>
    Object.entries(ops)
      .filter(([method]) => METHODS.includes(method))
      .map(([method, op]) => ({
        method: method.toUpperCase(),
        path: fill(path),
        permission: (op as { 'x-permission'?: string })['x-permission'] ?? '',
      }))
      .filter((op) => op.permission !== 'public' && op.permission !== 'authenticated'),
  );
}

describe('RBAC over the whole contract', () => {
  let api: TestApi;
  let ops: Operation[];

  beforeAll(async () => {
    api = await startTestApi();
    ops = protectedOperations(api.app.get(OPENAPI_DOCUMENT));
  });

  // Answers other than 403 are whatever the route does with an empty request.
  const status = async (op: Operation, token: string) =>
    (await api.do(op.method, op.path, undefined, { token, unchecked: true })).status;

  it('refuses every protected route to a token without its permission', async () => {
    const token = await api.token(randomUUID(), []);
    expect(ops.length).toBeGreaterThanOrEqual(100);
    for (const op of ops) {
      expect([op.method, op.path, await status(op, token)]).toEqual([op.method, op.path, 403]);
    }
  });

  it('lets every role reach exactly its seeded permissions', async () => {
    const rows = await api.app
      .get<Database>(DATABASE)
      .query<{ role: string; permission: string }>(
        'SELECT role, permission FROM identity.role_permissions',
      );
    const grants = new Map<string, Set<string>>();
    for (const r of rows.rows) {
      grants.set(r.role, (grants.get(r.role) ?? new Set()).add(r.permission));
    }
    expect(grants.size).toBe(6);
    for (const [role, has] of grants) {
      const token = await api.token(randomUUID(), [role]);
      for (const op of ops) {
        const forbidden = (await status(op, token)) === 403;
        expect([role, op.method, op.path, forbidden]).toEqual([
          role,
          op.method,
          op.path,
          !has.has(op.permission),
        ]);
      }
    }
  });
});
