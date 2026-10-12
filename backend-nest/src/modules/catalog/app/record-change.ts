import { CatalogEvents } from '../contract/events';
import { type CatalogRepository, type CatalogWriter } from '../port/catalog-repository';

/**
 * Runs a catalog write in a transaction, bumps the catalog version (expiring cached
 * trees) and announces the new version with `CatalogChanged`.
 */
export function recordChange(
  repo: CatalogRepository,
  write: (w: CatalogWriter) => Promise<void>,
): Promise<void> {
  return repo.transaction(async (w) => {
    await write(w);
    const version = await w.bumpVersion();
    await w.publish('catalog', { name: CatalogEvents.CatalogChanged, version });
  });
}
