import { readFileSync } from 'node:fs';
import { join } from 'node:path';
import { parse } from 'yaml';
import { z } from 'zod';
import { type AppConfig } from '../platform/config/app-config';
import { PACKAGE_ROOT } from '../platform/paths';
import {
  type AdminSeeder,
  type CatalogSeeder,
  type SeedAdmin,
  type SeedCategory,
} from '../platform/seeding/seeders';

/** The seed file shipped with the backend. */
export const SEED_CATALOG_PATH = join(PACKAGE_ROOT, 'seed', 'catalog.yaml');

const text = z.object({ en: z.string(), bn: z.string() });

const seedFile = z.object({
  categories: z
    .array(
      z.object({
        key: z.string(),
        name: text,
        icon: z.string(),
        services: z.array(
          z.object({
            key: z.string(),
            name: text,
            icon: z.string(),
            model: z.string(),
            required_level: z.number().int(),
            search_radius_m: z.number().int(),
            women_providers_only: z.boolean().default(false),
            requires_level_2: z.boolean().default(false),
            level2_checklist: z.array(text).default([]),
            sub_services: z.array(
              z.object({
                key: z.string(),
                name: text,
                unit: z.string(),
                price: z.number().int(),
                max_quantity: z.number().int(),
              }),
            ),
          }),
        ),
      }),
    )
    .default([]),
  admins: z
    .array(z.object({ email: z.string(), name: z.string(), roles: z.array(z.string()) }))
    .default([]),
});

type SeedFile = z.infer<typeof seedFile>;

/** Reads the seed YAML; prices in the file are whole taka and become paisa. */
export function parseSeed(raw: string): { categories: SeedCategory[]; admins: SeedAdmin[] } {
  let file: SeedFile;
  try {
    file = seedFile.parse(parse(raw));
  } catch (cause) {
    throw new Error('parse seed', { cause });
  }
  const categories = file.categories.map((c) => ({
    key: c.key,
    name: c.name,
    icon: c.icon,
    services: c.services.map((s) => ({
      key: s.key,
      name: s.name,
      icon: s.icon,
      model: s.model,
      requiredLevel: s.required_level,
      searchRadiusM: s.search_radius_m,
      womenProvidersOnly: s.women_providers_only,
      requiresLevel2: s.requires_level_2,
      level2Checklist: s.level2_checklist,
      subServices: s.sub_services.map((ss) => ({
        key: ss.key,
        name: ss.name,
        unit: ss.unit,
        pricePaisa: ss.price * 100,
        maxQuantity: ss.max_quantity,
      })),
    })),
  }));
  return { categories, admins: file.admins };
}

/** The module seams `seed` writes through. */
export interface Seeders {
  readonly catalog: CatalogSeeder;
  readonly admins: AdminSeeder;
}

/**
 * Loads the catalog and, outside production and only with SEED_ADMIN_PASSWORD set, the
 * demo admin users (P04 task 3). Idempotent.
 */
export async function seed(config: AppConfig, seeders: Seeders, raw: string): Promise<void> {
  const { categories, admins } = parseSeed(raw);
  try {
    await seeders.catalog.seedCatalog(categories);
  } catch (cause) {
    throw new Error('seed catalog', { cause });
  }
  if (config.appEnv === 'prod' || config.seedAdminPassword === '') {
    return;
  }
  for (const admin of admins) {
    try {
      await seeders.admins.ensureAdmin(admin, config.seedAdminPassword);
    } catch (cause) {
      throw new Error(`seed admin ${admin.email}`, { cause });
    }
  }
}

/** Reads the shipped seed file. */
export function readSeedCatalog(path: string = SEED_CATALOG_PATH): string {
  return readFileSync(path, 'utf8');
}
