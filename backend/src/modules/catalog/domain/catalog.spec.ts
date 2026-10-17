import {
  type Category,
  isValidCategory,
  isValidPrice,
  isValidService,
  isValidSubService,
  MODELS,
  publishedOnly,
  type Service,
  type ServiceFields,
  servicesOf,
  type SubService,
  UNITS,
} from './catalog';

const name = { en: 'Electrician', bn: 'ইলেকট্রিশিয়ান' };

const validService = (): ServiceFields => ({
  id: 's',
  categoryId: 'c',
  name,
  iconKey: 'bolt',
  model: 'on_demand',
  requiredLevel: 1,
  searchRadiusM: 5000,
  womenProvidersOnly: false,
  requiresLevel2: false,
  level2Checklist: [],
  sortOrder: 0,
  published: true,
});

describe('catalog rules', () => {
  it('validates categories', () => {
    expect(isValidCategory({ name, iconKey: 'plug' })).toBe(true);
    expect(isValidCategory({ name: { en: 'x', bn: '' }, iconKey: 'p' })).toBe(false);
    expect(isValidCategory({ name, iconKey: ' ' })).toBe(false);
  });

  it('validates services', () => {
    expect(isValidService(validService())).toBe(true);
    const broken: Partial<ServiceFields>[] = [
      { model: 'auction' },
      { requiredLevel: 3 },
      { requiredLevel: -1 },
      { searchRadiusM: 100 },
      { searchRadiusM: 50_001 },
      { iconKey: ' ' },
      { name: { en: 'x', bn: ' ' } },
      { requiresLevel2: true },
    ];
    for (const change of broken) {
      expect(isValidService({ ...validService(), ...change })).toBe(false);
    }
    expect(isValidService({ ...validService(), requiresLevel2: true, requiredLevel: 2 })).toBe(
      true,
    );
  });

  it('validates sub-services and prices', () => {
    expect(isValidSubService({ name, unit: 'unit', maxQuantity: 1 })).toBe(true);
    expect(isValidSubService({ name, unit: 'litre', maxQuantity: 1 })).toBe(false);
    expect(isValidSubService({ name, unit: 'job', maxQuantity: 0 })).toBe(false);
    expect(isValidPrice(0)).toBe(true);
    expect(isValidPrice(-1)).toBe(false);
  });

  it('keeps only published items without changing the tree', () => {
    const sub = (published: boolean) => ({ published }) as SubService;
    const service = (published: boolean, subServices: SubService[] = []) =>
      ({ ...validService(), published, subServices }) as Service;
    const tree = [
      { published: false, services: [] },
      { published: true, services: [service(false), service(true, [sub(true), sub(false)])] },
    ] as unknown as Category[];
    const got = publishedOnly(tree);
    expect(got).toHaveLength(1);
    expect(got[0]?.services).toHaveLength(1);
    expect(got[0]?.services[0]?.subServices).toHaveLength(1);
    expect(tree[1]?.services[1]?.subServices).toHaveLength(2);
    expect(servicesOf(got)).toHaveLength(1);
  });
});

describe('catalog vocabularies', () => {
  it('lists the service models and quantity units of PRD §4', () => {
    expect(MODELS).toEqual(['on_demand', 'duration_hire', 'listing', 'partner_referral']);
    expect(UNITS).toEqual(['job', 'unit', 'hour', 'day']);
  });
});
