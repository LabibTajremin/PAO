import { generateKeyPairSync } from 'node:crypto';
import { TokenSigner } from '../platform/auth/access-token';
import { FakeClock } from '../platform/clock/fake-clock';
import { type AppConfig } from '../platform/config/app-config';
import { UuidV7Generator } from '../platform/ids/id-generator';
import {
  ADMIN_SEEDER,
  CATALOG_SEEDER,
  PERF_SEEDER,
  type SeedAdmin,
  type SeedCategory,
} from '../platform/seeding/seeders';
import { PERF_CENTRE, seedPerf, spiralPoint } from './perf-seed';
import { parseSeed, readSeedCatalog, seed, SEED_CATALOG_PATH } from './seed';

const raw = readSeedCatalog();

function seeders() {
  const catalogs: SeedCategory[][] = [];
  const admins: [SeedAdmin, string][] = [];
  return {
    catalogs,
    admins,
    seeders: {
      catalog: {
        seedCatalog: (c: readonly SeedCategory[]) => {
          catalogs.push([...c]);
          return Promise.resolve();
        },
      },
      admins: {
        ensureAdmin: (a: SeedAdmin, password: string) => {
          admins.push([a, password]);
          return a.roles.includes('customer')
            ? Promise.reject(new Error('customer role'))
            : Promise.resolve();
        },
      },
    },
  };
}

const dev = { appEnv: 'dev', seedAdminPassword: 'demo password 2026' } as AppConfig;

describe('seed', () => {
  it('reads the shipped catalog with prices in paisa', () => {
    const { categories, admins } = parseSeed(raw);
    const electrician = categories[0]?.services[0];
    expect(electrician?.key).toBe('electrician');
    expect(electrician?.subServices[0]).toMatchObject({ key: 'fan-install', pricePaisa: 50_000 });
    expect(electrician?.womenProvidersOnly).toBe(false);
    expect(admins.map((a) => a.email)).toContain('verifier@pao.bd');
    expect(SEED_CATALOG_PATH).toMatch(/seed\/catalog\.yaml$/);
  });

  it('seeds the catalog and the demo admins outside production', async () => {
    const s = seeders();
    await seed(dev, s.seeders, raw);
    expect(s.catalogs).toHaveLength(1);
    expect(s.admins.map(([a, p]) => `${a.email} ${p}`)).toContain(
      'super@pao.bd demo password 2026',
    );
  });

  it('skips admins in production or without a password', async () => {
    for (const config of [
      { ...dev, appEnv: 'prod' },
      { ...dev, seedAdminPassword: '' },
    ] as AppConfig[]) {
      const s = seeders();
      await seed(config, s.seeders, raw);
      expect(s.admins).toEqual([]);
    }
  });

  it('reports broken files and failing seams', async () => {
    const s = seeders();
    await expect(seed(dev, s.seeders, 'categories: [')).rejects.toThrow('parse seed');
    const customerAdmin = 'admins:\n  - {email: x@pao.bd, name: X, roles: [customer]}\n';
    await expect(seed(dev, s.seeders, customerAdmin)).rejects.toThrow('seed admin x@pao.bd');
    const failing = {
      ...s.seeders,
      catalog: { seedCatalog: () => Promise.reject(new Error('db down')) },
    };
    await expect(seed(dev, failing, raw)).rejects.toThrow('seed catalog');
  });
});

describe('seedPerf', () => {
  const clock = new FakeClock(new Date('2026-10-09T10:00:00Z'));
  const signer = new TokenSigner(
    { keyId: 'k1', key: generateKeyPairSync('ed25519').privateKey, ttlMs: 2 * 3600_000 },
    clock,
    new UuidV7Generator(),
  );

  it('puts providers online around Banani and signs customer tokens', async () => {
    const placed: { lat: number; lng: number }[] = [];
    const seeder = {
      serviceId: 's1',
      subServiceId: 'ss1',
      addOnlineProvider: (_id: string, at: { lat: number; lng: number }) => {
        placed.push(at);
        return Promise.resolve();
      },
    };
    const fixture = await seedPerf(dev, seeder, signer, 30);
    expect(placed).toHaveLength(30);
    expect(placed[0]).toEqual(PERF_CENTRE);
    expect(spiralPoint(29, 30).lat).not.toBe(PERF_CENTRE.lat);
    expect(fixture).toMatchObject({
      serviceId: 's1',
      subServiceId: 'ss1',
      lat: 23.7937,
      lng: 90.4066,
    });
    expect(fixture.tokens).toHaveLength(50);
  });

  it('refuses to run in production', async () => {
    const seeder = { serviceId: '', subServiceId: '', addOnlineProvider: () => Promise.resolve() };
    await expect(seedPerf({ appEnv: 'prod' } as AppConfig, seeder, signer, 1)).rejects.toThrow(
      'refuses to run in production',
    );
  });
});

describe('seeder seams', () => {
  it('are distinct injection tokens the modules provide', () => {
    expect(new Set([CATALOG_SEEDER, ADMIN_SEEDER, PERF_SEEDER]).size).toBe(3);
  });
});
