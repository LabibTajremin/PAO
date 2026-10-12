// The migration tool: `up` applies the module migrations, `seed` loads the catalog and
// demo admins, `perf-seed N` prints the load-test fixture (./pao seed, ./pao perf).
import 'reflect-metadata';
import { NestFactory } from '@nestjs/core';
import { BackendModule } from './app/backend.module';
import { seedPerf } from './app/perf-seed';
import { readSeedCatalog, seed } from './app/seed';
import { TokenSigner } from './platform/auth/access-token';
import { CLOCK, type Clock } from './platform/clock/clock';
import { loadConfig } from './platform/config/load-config';
import { connectDatabase } from './platform/db/database';
import { migrationFiles, readModuleLists } from './platform/db/migration-files';
import { Migrator } from './platform/db/migrator';
import { ID_GENERATOR, type IdGenerator } from './platform/ids/id-generator';
import { createLogger } from './platform/logging/logger';
import {
  ADMIN_SEEDER,
  type AdminSeeder,
  CATALOG_SEEDER,
  type CatalogSeeder,
  PERF_SEEDER,
  type PerfSeeder,
} from './platform/seeding/seeders';

const USAGE = 'usage: migrate up|seed|perf-seed N';

async function up(): Promise<void> {
  const db = await connectDatabase(process.env.DATABASE_URL ?? '');
  try {
    await new Migrator(db, migrationFiles(), readModuleLists().modules).up();
  } finally {
    await db.close();
  }
}

async function withModules(fn: (get: (token: symbol) => unknown) => Promise<void>) {
  const config = loadConfig(process.env);
  const app = await NestFactory.createApplicationContext(BackendModule.forRoot(config), {
    logger: false,
  });
  try {
    await fn((token: symbol) => app.get(token, { strict: false }));
  } finally {
    await app.close();
  }
}

function seedData(): Promise<void> {
  return withModules((get) =>
    seed(
      loadConfig(process.env),
      {
        catalog: get(CATALOG_SEEDER) as CatalogSeeder,
        admins: get(ADMIN_SEEDER) as AdminSeeder,
      },
      readSeedCatalog(),
    ),
  );
}

function perfSeed(n: number): Promise<void> {
  return withModules(async (get) => {
    const config = loadConfig(process.env);
    const signer = new TokenSigner(
      { keyId: config.jwt.keyId, key: config.jwt.signingKey, ttlMs: 2 * 60 * 60 * 1000 },
      get(CLOCK) as Clock,
      get(ID_GENERATOR) as IdGenerator,
    );
    const fixture = await seedPerf(config, get(PERF_SEEDER) as PerfSeeder, signer, n);
    process.stdout.write(JSON.stringify(fixture) + '\n');
  });
}

function run(args: string[]): Promise<void> {
  const [command, count] = args;
  if (args.length === 1 && command === 'up') {
    return up();
  }
  if (args.length === 1 && command === 'seed') {
    return seedData();
  }
  const n = Number(count);
  if (args.length === 2 && command === 'perf-seed' && Number.isInteger(n) && n >= 1) {
    return perfSeed(n);
  }
  return Promise.reject(new Error(USAGE));
}

run(process.argv.slice(2)).catch((err: unknown) => {
  createLogger('error').error({ err }, 'migrate failed');
  process.exit(1);
});
