// The catalog use cases wired to fakes, for specs (the Go newService and seedTree).
import { v4 as uuidv4 } from 'uuid';
import { FakeClock } from '../../../platform/clock/fake-clock';
import { UuidV7Generator } from '../../../platform/ids/id-generator';
import { discardLogger } from '../../../platform/logging/logger';
import { RedisKeys } from '../../../platform/redis/redis-client';
import { BrowseCatalog } from './browse-catalog';
import { CatalogTree } from './catalog-tree';
import { ChangePrice } from './change-price';
import { EditCatalog } from './edit-catalog';
import { FakeCatalogRepository, FakeTreeCache } from './fake-catalog';
import { SeedCatalog } from './seed-catalog';

/** A name in both languages. */
export const NAME = { en: 'Electrician', bn: 'ইলেকট্রিশিয়ান' };

/** Every catalog use case over one fake repository and cache. */
export function fakeCatalog() {
  const repo = new FakeCatalogRepository();
  const cache = new FakeTreeCache();
  const clock = new FakeClock(new Date('2026-10-09T10:00:00Z'));
  const ids = new UuidV7Generator();
  const tree = new CatalogTree(repo, cache, new RedisKeys('t'), discardLogger());
  return {
    repo,
    cache,
    clock,
    tree,
    browse: new BrowseCatalog(repo, tree),
    edit: new EditCatalog(repo, clock, ids),
    prices: new ChangePrice(repo, clock, ids),
    seeder: new SeedCatalog(repo, clock, ids),
  };
}

/** A valid on-demand service in `categoryId`. */
export function serviceDraft(categoryId: string) {
  return {
    categoryId,
    name: NAME,
    iconKey: 'bolt',
    model: 'on_demand',
    requiredLevel: 1,
    searchRadiusM: 5000,
    womenProvidersOnly: false,
    requiresLevel2: false,
    level2Checklist: [],
    sortOrder: 0,
    published: true,
  };
}

/** A valid, published sub-service of `serviceId`. */
export function subServiceDraft(serviceId: string) {
  return {
    serviceId,
    name: NAME,
    description: NAME,
    inclusions: [],
    exclusions: [],
    unit: 'unit',
    maxQuantity: 5,
    sortOrder: 0,
    published: true,
  };
}

/** Saves a published category → service → sub-service (৳500) tree. */
export async function seedTree(edit: EditCatalog) {
  const category = await edit.saveCategory({
    name: NAME,
    iconKey: 'plug',
    sortOrder: 0,
    published: true,
  });
  const service = await edit.saveService(serviceDraft(category.id));
  const sub = await edit.createSubService(subServiceDraft(service.id), 50_000, uuidv4());
  return { category, service, sub };
}
