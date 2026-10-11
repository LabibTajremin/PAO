import { readFileSync } from 'node:fs';
import { join } from 'node:path';
import { Test } from '@nestjs/testing';
import { parse } from 'yaml';
import { migratedDatabase } from '../../../test/kit/postgres';
import { closedRedis, testRedis } from '../../../test/kit/redis';
import { standIn } from '../../../test/kit/stand-in';
import { type AppConfig } from '../config/app-config';
import { ConfigModule } from '../config/config.module';
import { connectDatabase, type Database } from '../db/database';
import { DatabaseModule } from '../db/database.module';
import { PACKAGE_ROOT } from '../paths';
import { REDIS, REDIS_KEYS } from '../redis/redis-client';
import { type Grants, PostgresRbacSource, type RbacSource, RbacChecker } from './rbac';
import { RbacModule } from './rbac.module';

class FakeSource implements RbacSource {
  loads = 0;
  failure?: Error;
  constructor(public grants: Record<string, Grants>) {}

  loadGrants(role: string): Promise<Grants> {
    this.loads++;
    if (this.failure) {
      return Promise.reject(this.failure);
    }
    return Promise.resolve(this.grants[role] ?? { permissions: [], screens: [] });
  }
}

describe('RbacChecker', () => {
  it('caches grants per version', async () => {
    const { redis, keys } = await testRedis();
    const source = new FakeSource({
      customer: { permissions: ['booking:create', 'booking:read:own'], screens: ['C07'] },
      provider: { permissions: ['job:respond', 'booking:read:own'], screens: ['M15'] },
    });
    const rbac = new RbacChecker(redis, keys, source);
    expect(await rbac.grants(['customer', 'provider', 'empty'])).toEqual({
      permissions: ['booking:create', 'booking:read:own', 'job:respond'],
      screens: ['C07', 'M15'],
    });
    expect(await rbac.has(['customer', 'empty'], 'booking:create')).toBe(true);
    expect(source.loads).toBe(3);
    expect(await rbac.has(['customer'], 'job:respond')).toBe(false);
    source.grants.customer = { permissions: ['job:respond'], screens: [] };
    expect(await rbac.bumpVersion()).toBe(1);
    expect(await rbac.has(['customer'], 'job:respond')).toBe(true);
    expect(await redis.ttl(keys.key('rbac', 'role', 'customer', 'v1'))).toBeGreaterThan(3500);
  });

  it('reports source, Redis and data errors', async () => {
    const { redis, keys } = await testRedis();
    const failing = new FakeSource({});
    failing.failure = new Error('db down');
    await expect(new RbacChecker(redis, keys, failing).has(['customer'], 'x')).rejects.toThrow(
      'load grants for customer',
    );
    const closed = new RbacChecker(await closedRedis(), keys, new FakeSource({}));
    await expect(closed.grants(['customer'])).rejects.toThrow();
    await expect(closed.bumpVersion()).rejects.toThrow();
    await redis.set(keys.key('rbac', 'version'), 'x');
    await expect(new RbacChecker(redis, keys, new FakeSource({})).version()).rejects.toThrow(
      'not a number',
    );
    await redis.set(keys.key('rbac', 'version'), '0');
    await redis.set(keys.key('rbac', 'role', 'r', 'v0'), 'string-not-set');
    await expect(new RbacChecker(redis, keys, new FakeSource({})).grants(['r'])).rejects.toThrow();
    await redis.sadd(keys.key('rbac', 'role', 's', 'v0'), 'p');
    await redis.set(keys.key('rbac', 'screens', 's', 'v0'), 'string-not-set');
    await expect(new RbacChecker(redis, keys, new FakeSource({})).grants(['s'])).rejects.toThrow();
  });
});

describe('PostgresRbacSource over the seeded roles', () => {
  let db: Database;

  beforeAll(async () => {
    db = await connectDatabase(await migratedDatabase());
  });

  afterAll(() => db.close());

  it('loads permissions and screens of a role', async () => {
    const g = await new PostgresRbacSource(db).loadGrants('customer');
    expect(g.permissions).toContain('booking:create');
    expect(g.screens).toContain('C07');
    expect(await new PostgresRbacSource(db).loadGrants('nobody')).toEqual({
      permissions: [],
      screens: [],
    });
  });

  it('grants every x-permission of the spec to some role', async () => {
    const spec = parse(
      readFileSync(join(PACKAGE_ROOT, 'src/platform/http/openapi.gen.yaml'), 'utf8'),
    ) as { paths: Record<string, Record<string, { 'x-permission'?: string }>> };
    const perms = new Set<string>();
    for (const [path, ops] of Object.entries(spec.paths)) {
      for (const [method, op] of Object.entries(ops)) {
        expect(`${method} ${path} ${op['x-permission'] ?? 'missing'}`).not.toMatch(/missing$/);
        perms.add(op['x-permission'] ?? '');
      }
    }
    perms.delete('public');
    perms.delete('authenticated');
    for (const perm of perms) {
      const { rows } = await db.query(
        'SELECT 1 FROM identity.role_permissions WHERE permission = $1',
        [perm],
      );
      expect(`${perm}: ${rows.length > 0 ? 'granted' : 'granted to no role'}`).toBe(
        `${perm}: granted`,
      );
    }
  });

  it('assigns every screen of 05-screens.md to some role', async () => {
    const doc = readFileSync(join(PACKAGE_ROOT, '../docs/build/05-screens.md'), 'utf8');
    const ids = [...doc.matchAll(/^\| ([CMA][0-9]{2}b?(?:[,–] ?[CMA][0-9]{2}b?)*)/gm)].flatMap(
      (m) => expandScreenIds(m[1] ?? ''),
    );
    expect(ids.length).toBeGreaterThanOrEqual(100);
    for (const id of ids) {
      const { rows } = await db.query('SELECT 1 FROM identity.role_screens WHERE screen_id = $1', [
        id,
      ]);
      expect(`${id}: ${rows.length}`).not.toBe(`${id}: 0`);
    }
  });
});

/** Turns "C02, C31" or "M05–M13" into individual screen ids. */
function expandScreenIds(cell: string): string[] {
  const range = /^([CMA])(\d{2})–[CMA](\d{2})$/.exec(cell);
  if (!range) {
    return cell.match(/[CMA][0-9]{2}b?/g) ?? [];
  }
  const out: string[] = [];
  for (let n = Number(range[2]); n <= Number(range[3]); n++) {
    out.push(`${range[1] ?? ''}${String(n).padStart(2, '0')}`);
  }
  return out;
}

describe('RbacModule', () => {
  it('wires the checker to the identity tables', async () => {
    const { redis, keys } = await testRedis();
    const ref = await Test.createTestingModule({
      imports: [
        ConfigModule.forRoot({ databaseUrl: await migratedDatabase() } as AppConfig),
        DatabaseModule,
        standIn(
          new Map<symbol, unknown>([
            [REDIS, redis],
            [REDIS_KEYS, keys],
          ]),
        ),
        RbacModule,
      ],
    }).compile();
    const app = await ref.createNestApplication().init();
    expect(await app.get(RbacChecker).has(['super_admin'], 'role:manage')).toBe(true);
    await app.close();
  });
});
