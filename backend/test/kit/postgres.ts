// A private Postgres database per spec, cloned from a migrated template built once per
// migration set (ADR-0008). Other agents share the
// server, so only databases created here are ever dropped.
import { createHash, randomUUID } from 'node:crypto';
import { readdirSync, readFileSync, statSync } from 'node:fs';
import { join, relative } from 'node:path';
import { Client } from 'pg';
import { connectDatabase } from '../../src/platform/db/database';
import {
  MIGRATIONS_DIR,
  migrationFiles,
  readModuleLists,
} from '../../src/platform/db/migration-files';
import { Migrator } from '../../src/platform/db/migrator';
import { onCleanup, testEnv } from './cleanup';

const TEMPLATE_LOCK = 424243;

/** Returns `url` pointing at database `name`. */
export function withDatabase(url: string, name: string): string {
  const u = new URL(url);
  u.pathname = '/' + name;
  return u.toString();
}

async function admin<T>(fn: (c: Client) => Promise<T>): Promise<T> {
  const client = new Client({ connectionString: testEnv('PAO_TEST_DATABASE_URL') });
  await client.connect();
  try {
    return await fn(client);
  } finally {
    await client.end();
  }
}

async function createDatabase(template?: string): Promise<string> {
  const name = 'pao_nest_test_' + randomUUID().replaceAll('-', '');
  await admin((c) => c.query(`CREATE DATABASE ${name}${template ? ` TEMPLATE ${template}` : ''}`));
  onCleanup(() => admin((c) => c.query(`DROP DATABASE IF EXISTS ${name} WITH (FORCE)`)));
  return withDatabase(testEnv('PAO_TEST_DATABASE_URL'), name);
}

/** Creates a fresh, empty database dropped when the spec file ends. */
export function emptyDatabase(): Promise<string> {
  return createDatabase();
}

/** Creates a fresh database with every migration applied. */
export async function migratedDatabase(): Promise<string> {
  return createDatabase(await ensureTemplate());
}

function listFiles(dir: string): string[] {
  return readdirSync(dir).flatMap((n) => {
    const path = join(dir, n);
    return statSync(path).isDirectory() ? listFiles(path) : [path];
  });
}

function migrationsHash(): string {
  const h = createHash('sha256');
  for (const path of listFiles(MIGRATIONS_DIR).sort()) {
    h.update(`${relative(MIGRATIONS_DIR, path)}\n`)
      .update(readFileSync(path))
      .update('\n');
  }
  return h.digest('hex').slice(0, 16);
}

async function ensureTemplate(): Promise<string> {
  const name = 'pao_nest_tpl_' + migrationsHash();
  await admin(async (c) => {
    await c.query('SELECT pg_advisory_lock($1)', [TEMPLATE_LOCK]);
    const { rows } = await c.query('SELECT 1 FROM pg_database WHERE datname = $1', [name]);
    if (rows.length === 0) {
      await buildTemplate(c, name);
    }
    await c.query('SELECT pg_advisory_unlock($1)', [TEMPLATE_LOCK]);
  });
  return name;
}

async function buildTemplate(c: Client, name: string): Promise<void> {
  await c.query(`CREATE DATABASE ${name}`);
  const db = await connectDatabase(withDatabase(testEnv('PAO_TEST_DATABASE_URL'), name));
  try {
    await new Migrator(db, migrationFiles(), readModuleLists().modules).up();
  } catch (err) {
    await db.close();
    await c.query(`DROP DATABASE IF EXISTS ${name} WITH (FORCE)`);
    throw err;
  }
  await db.close();
}
