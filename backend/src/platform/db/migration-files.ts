import { readdir, readFile } from 'node:fs/promises';
import { readFileSync } from 'node:fs';
import { join } from 'node:path';
import { PACKAGE_ROOT } from '../paths';
import { type GooseMigration, migrationVersion, parseGooseMigration } from './goose-parser';

/** Where the per-module goose migrations live. */
export const MIGRATIONS_DIR = join(PACKAGE_ROOT, 'migrations');

/** The module folders in apply order, and the modules that own an outbox table. */
export interface ModuleLists {
  readonly modules: readonly string[];
  readonly outboxModules: readonly string[];
}

const MODULE_NAME = /^[a-z][a-z0-9_]*$/;

function stringList(value: unknown, field: string): string[] {
  if (!Array.isArray(value) || !value.every((v) => typeof v === 'string' && MODULE_NAME.test(v))) {
    throw new Error(`modules.json: ${field} must be a list of module names`);
  }
  return value as string[];
}

/** Reads `modules.json`, which lists the modules in the order they are migrated. */
export function readModuleLists(dir: string = MIGRATIONS_DIR): ModuleLists {
  const raw = JSON.parse(readFileSync(join(dir, 'modules.json'), 'utf8')) as Record<
    string,
    unknown
  >;
  return {
    modules: stringList(raw.modules, 'modules'),
    outboxModules: stringList(raw.outboxModules, 'outboxModules'),
  };
}

/** Returns a loader of one module's migrations from `dir/<module>/NNNN_name.sql`. */
export function migrationFiles(dir: string = MIGRATIONS_DIR) {
  return async (module: string): Promise<GooseMigration[]> => {
    if (!MODULE_NAME.test(module)) {
      throw new Error(`invalid migration module name ${JSON.stringify(module)}`);
    }
    const names = (await readdir(join(dir, module)).catch(() => [])).filter(
      (n) => migrationVersion(n) !== undefined,
    );
    if (names.length === 0) {
      throw new Error(`no migrations found for module ${module}`);
    }
    const files = await Promise.all(
      names.map(async (n) =>
        parseGooseMigration(`${module}/${n}`, await readFile(join(dir, module, n), 'utf8')),
      ),
    );
    return files.sort((a, b) => a.version - b.version);
  };
}
