// Catalog helpers (the Go testkit/seed.go).
import { readSeedCatalog, parseSeed } from '../../src/app/seed';
import { CATALOG_SEEDER, type CatalogSeeder } from '../../src/platform/seeding/seeders';
import { type TestApi } from './api';

/** Loads `seed/catalog.yaml` into the test API's database, as `migrate seed` does. */
export async function seedCatalog(api: TestApi): Promise<void> {
  const seeder = api.app.get<symbol, CatalogSeeder>(CATALOG_SEEDER, { strict: false });
  await seeder.seedCatalog(parseSeed(readSeedCatalog()).categories);
}
