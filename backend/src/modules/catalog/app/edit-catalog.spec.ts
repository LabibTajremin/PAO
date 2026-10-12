import { v4 as uuidv4 } from 'uuid';
import { CatalogEvents } from '../contract/events';
import { CatalogReason } from '../domain/errors';
import { type FakeCatalogMethod } from './fake-catalog';
import { fakeCatalog, NAME, seedTree, serviceDraft, subServiceDraft } from './fake-catalog-harness';

const boom = new Error('boom');

describe('ChangePrice', () => {
  it('versions prices and keeps the history', async () => {
    const c = fakeCatalog();
    const { sub } = await seedTree(c.edit);
    const before = c.repo.currentVersion;
    const actor = uuidv4();
    const price = await c.prices.change(sub.id, 60_000, actor);
    expect(price.amount).toBe(60_000);
    expect(c.repo.currentVersion).toBe(before + 1);
    const history = await c.prices.history(sub.id);
    expect(history.map((p) => p.amount)).toEqual([60_000, 50_000]);
    expect(c.repo.events.slice(-2)).toEqual([
      {
        name: CatalogEvents.PriceChanged,
        subServiceId: sub.id,
        priceVersionId: price.id,
        amountPaisa: 60_000,
        actorId: actor,
      },
      { name: CatalogEvents.CatalogChanged, version: before + 1 },
    ]);
  });

  it('refuses bad prices and unknown sub-services', async () => {
    const c = fakeCatalog();
    const { sub } = await seedTree(c.edit);
    const actor = uuidv4();
    await expect(c.prices.change(sub.id, -1, actor)).rejects.toMatchObject({
      reason: CatalogReason.PriceNegative,
    });
    const notFound = { reason: CatalogReason.NotFound };
    await expect(c.prices.change(uuidv4(), 1, actor)).rejects.toMatchObject(notFound);
    await expect(c.prices.history(uuidv4())).rejects.toMatchObject(notFound);
    c.repo.faults.set('addPrice', boom);
    await expect(c.prices.change(sub.id, 1, actor)).rejects.toBe(boom);
  });
});

describe('EditCatalog', () => {
  it('updates categories, services and sub-services', async () => {
    const c = fakeCatalog();
    const { category, service, sub } = await seedTree(c.edit);
    expect((await c.edit.saveCategory({ ...category, published: false })).published).toBe(false);
    const moved = await c.edit.saveService({ ...service, searchRadiusM: 8000 });
    expect(moved.searchRadiusM).toBe(8000);
    const updated = await c.edit.updateSubService({ ...sub, maxQuantity: 9 });
    expect(updated).toMatchObject({ maxQuantity: 9, price: 50_000 });
  });

  it('refuses invalid or unknown items', async () => {
    const c = fakeCatalog();
    const { category, service } = await seedTree(c.edit);
    const blankName = { en: '', bn: '' };
    const unknownCategory = { ...serviceDraft(uuidv4()) };
    const attempts = [
      c.edit.saveCategory({ name: blankName, iconKey: '', sortOrder: 0, published: false }),
      c.edit.saveCategory({
        id: uuidv4(),
        name: NAME,
        iconKey: 'x',
        sortOrder: 0,
        published: false,
      }),
      c.edit.saveService({ ...serviceDraft(category.id), model: '' }),
      c.edit.saveService(unknownCategory),
      c.edit.saveService({ ...serviceDraft(category.id), id: uuidv4() }),
      c.edit.createSubService({ ...subServiceDraft(service.id), unit: '' }, 1, uuidv4()),
      c.edit.createSubService(subServiceDraft(service.id), -5, uuidv4()),
      c.edit.createSubService(subServiceDraft(uuidv4()), 1, uuidv4()),
      c.edit.updateSubService({ ...subServiceDraft(service.id), id: uuidv4() }),
      c.edit.updateSubService({ ...subServiceDraft(service.id), id: uuidv4(), name: blankName }),
    ];
    for (const attempt of attempts) {
      await expect(attempt).rejects.toHaveProperty('reason');
    }
  });

  it.each<FakeCatalogMethod>([
    'transaction',
    'saveCategory',
    'saveService',
    'saveSubService',
    'bumpVersion',
    'publish',
    'categoryExists',
  ])('reports a failing %s', async (method) => {
    const c = fakeCatalog();
    const { category, service, sub } = await seedTree(c.edit);
    c.repo.faults.set(method, boom);
    const results = await Promise.allSettled([
      c.edit.saveCategory(category),
      c.edit.saveService(service),
      c.edit.createSubService(subServiceDraft(service.id), 1, uuidv4()),
      c.edit.updateSubService(sub),
    ]);
    expect(results.some((r) => r.status === 'rejected' && r.reason === boom)).toBe(true);
  });
});
