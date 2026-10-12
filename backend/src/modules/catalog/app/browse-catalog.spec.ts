import { v4 as uuidv4 } from 'uuid';
import { CatalogReason } from '../domain/errors';
import { fakeCatalog, seedTree } from './fake-catalog-harness';

const boom = new Error('boom');
const notFound = { reason: CatalogReason.NotFound };

describe('CatalogTree', () => {
  it('caches the published tree per version', async () => {
    const c = fakeCatalog();
    await seedTree(c.edit);
    c.repo.treeReads = 0;
    const first = await c.tree.published();
    expect(first.categories).toHaveLength(1);
    expect(first.categories[0]?.services[0]?.subServices[0]?.price).toBe(50_000);
    await c.tree.published();
    expect(c.repo.treeReads).toBe(1);
    expect(c.cache.items.has(`pao:t:cache:catalog:v${String(c.repo.currentVersion)}`)).toBe(true);
  });

  it('reads the database when the cache fails', async () => {
    const c = fakeCatalog();
    await seedTree(c.edit);
    c.cache.failure = boom;
    expect((await c.tree.published()).categories).toHaveLength(1);
    expect((await c.tree.published()).categories).toHaveLength(1);
    expect(c.repo.treeReads).toBe(2);
  });

  it('shows admins everything', async () => {
    const c = fakeCatalog();
    const { category } = await seedTree(c.edit);
    await c.edit.saveCategory({ ...category, published: false });
    expect((await c.tree.published()).categories).toHaveLength(0);
    expect((await c.tree.all()).categories).toHaveLength(1);
  });

  it.each(['version', 'tree'] as const)('reports a failing %s', async (method) => {
    const c = fakeCatalog();
    c.repo.faults.set(method, boom);
    await expect(c.tree.published()).rejects.toBe(boom);
    await expect(c.tree.all()).rejects.toBe(boom);
    await expect(c.browse.publishedService(uuidv4())).rejects.toBe(boom);
    await expect(c.browse.publishedServices()).rejects.toBe(boom);
  });
});

describe('BrowseCatalog', () => {
  it('finds published services and search hits', async () => {
    const c = fakeCatalog();
    const { service, sub } = await seedTree(c.edit);
    expect((await c.browse.publishedService(service.id)).id).toBe(service.id);
    await expect(c.browse.publishedService(uuidv4())).rejects.toMatchObject(notFound);
    c.repo.hits = { serviceIds: [service.id, uuidv4()], subServiceIds: [sub.id, uuidv4()] };
    const found = await c.browse.search('fan');
    expect(found.services.map((s) => s.id)).toEqual([service.id]);
    expect(found.subServices.map((s) => s.id)).toEqual([sub.id]);
    expect(await c.browse.publishedServices()).toHaveLength(1);
  });

  it('reports search failures', async () => {
    const c = fakeCatalog();
    c.repo.faults.set('search', boom);
    await expect(c.browse.search('x')).rejects.toBe(boom);
    c.repo.faults.clear();
    c.repo.faults.set('version', boom);
    await expect(c.browse.search('x')).rejects.toBe(boom);
  });

  it('returns price snapshots and any service', async () => {
    const c = fakeCatalog();
    const { service, sub } = await seedTree(c.edit);
    const snap = await c.browse.priceSnapshot(sub.id);
    expect(snap.service.id).toBe(service.id);
    expect(snap.subService.price).toBe(50_000);
    await expect(c.browse.priceSnapshot(uuidv4())).rejects.toMatchObject(notFound);
    expect((await c.browse.service(service.id)).id).toBe(service.id);
  });
});
