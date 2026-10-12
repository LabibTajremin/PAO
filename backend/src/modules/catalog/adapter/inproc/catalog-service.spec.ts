import { v4 as uuidv4 } from 'uuid';
import { CatalogErrors } from '../../contract/errors';
import { fakeCatalog, seedTree } from '../../app/fake-catalog-harness';
import { InprocCatalogService } from './catalog-service';

describe('InprocCatalogService', () => {
  it('answers with contract shapes', async () => {
    const c = fakeCatalog();
    const { service, sub } = await seedTree(c.edit);
    const contract = new InprocCatalogService(c.browse);
    expect(await contract.getService(service.id)).toMatchObject({
      id: service.id,
      model: 'on_demand',
      level2Checklist: [],
    });
    expect(await contract.getPriceSnapshot(sub.id)).toMatchObject({
      subServiceId: sub.id,
      serviceId: service.id,
      priceVersionId: sub.priceVersionId,
      amountPaisa: 50_000,
      unit: 'unit',
      published: true,
    });
    expect(await contract.listServices()).toHaveLength(1);
  });

  it('names what was not found', async () => {
    const c = fakeCatalog();
    const contract = new InprocCatalogService(c.browse);
    await expect(contract.getService(uuidv4())).rejects.toMatchObject({
      reason: CatalogErrors.ServiceNotFound,
    });
    await expect(contract.getPriceSnapshot(uuidv4())).rejects.toMatchObject({
      reason: CatalogErrors.SubServiceNotFound,
    });
  });

  it('passes other failures through', async () => {
    const c = fakeCatalog();
    const { sub } = await seedTree(c.edit);
    const contract = new InprocCatalogService(c.browse);
    const boom = new Error('boom');
    c.repo.faults.set('subService', boom);
    await expect(contract.getPriceSnapshot(sub.id)).rejects.toBe(boom);
  });
});
