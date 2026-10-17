import { CATALOG_SERVICE, CatalogErrors, CatalogEvents, PriceUnit, ServiceModel } from './index';

describe('catalog contract', () => {
  it('keeps the stored event names of the Go backend', () => {
    expect(CatalogEvents).toEqual({
      CatalogChanged: 'catalog.CatalogChanged',
      PriceChanged: 'catalog.PriceChanged',
    });
  });

  it('scopes every error reason to catalog', () => {
    const reasons = Object.values(CatalogErrors);
    expect(reasons.every((r) => r.startsWith('catalog.'))).toBe(true);
    expect(new Set(reasons).size).toBe(reasons.length);
  });

  it('matches the model and unit values stored in the database', () => {
    expect(Object.values(ServiceModel)).toEqual([
      'on_demand',
      'duration_hire',
      'listing',
      'partner_referral',
    ]);
    expect(Object.values(PriceUnit)).toEqual(['job', 'unit', 'hour', 'day']);
  });

  it('names its injection token after the service', () => {
    expect(CATALOG_SERVICE.description).toBe('CatalogService');
  });
});
