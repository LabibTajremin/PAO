import { type SeedCategory } from '../../../platform/seeding/seeders';
import { CatalogReason } from '../domain/errors';
import { type FakeCatalogMethod } from './fake-catalog';
import { fakeCatalog, NAME } from './fake-catalog-harness';
import { seedId } from './seed-catalog';

function seedData(pricePaisa: number, model = 'on_demand'): SeedCategory[] {
  return [
    {
      key: 'electrical',
      name: NAME,
      icon: 'plug',
      services: [
        {
          key: 'electrician',
          name: NAME,
          icon: 'bolt',
          model,
          requiredLevel: 1,
          searchRadiusM: 5000,
          womenProvidersOnly: false,
          requiresLevel2: false,
          level2Checklist: [],
          subServices: [{ key: 'fan', name: NAME, unit: 'unit', pricePaisa, maxQuantity: 5 }],
        },
      ],
    },
  ];
}

describe('SeedCatalog', () => {
  it('is idempotent and versions changed prices', async () => {
    const c = fakeCatalog();
    await c.seeder.seedCatalog(seedData(50_000));
    await c.seeder.seedCatalog(seedData(50_000));
    expect([c.repo.categories.size, c.repo.services.size, c.repo.subs.size]).toEqual([1, 1, 1]);
    expect(c.repo.prices).toHaveLength(1);
    expect(c.repo.prices[0]?.createdBy).toBe('00000000-0000-0000-0000-000000000000');
    await c.seeder.seedCatalog(seedData(60_000));
    expect(c.repo.prices).toHaveLength(2);
    expect(c.repo.services.get(seedId('service', 'electrician'))?.published).toBe(true);
  });

  it('derives the same ids as the Go backend', () => {
    // UUIDv5 values of the Go SeedID, so reseeding a Go-seeded database updates its rows.
    expect(seedId('service', 'electrician')).toBe('36dab175-76f7-5578-9d1a-bfec11c6c195');
    expect(seedId('sub-service', 'fan-install')).toBe('7cdd227b-0d87-5563-b8f8-f552050149bd');
  });

  it('refuses an invalid service', async () => {
    const c = fakeCatalog();
    await expect(c.seeder.seedCatalog(seedData(1, 'auction'))).rejects.toMatchObject({
      reason: CatalogReason.Invalid,
    });
  });

  it.each<FakeCatalogMethod>(['saveCategory', 'saveService', 'saveSubService', 'addPrice'])(
    'reports a failing %s',
    async (method) => {
      const c = fakeCatalog();
      const boom = new Error('boom');
      c.repo.faults.set(method, boom);
      await expect(c.seeder.seedCatalog(seedData(1))).rejects.toBe(boom);
    },
  );

  it('reports a failing price read', async () => {
    const c = fakeCatalog();
    await c.seeder.seedCatalog(seedData(1));
    const boom = new Error('boom');
    c.repo.faults.set('subService', boom);
    await expect(c.seeder.seedCatalog(seedData(1))).rejects.toBe(boom);
  });
});
