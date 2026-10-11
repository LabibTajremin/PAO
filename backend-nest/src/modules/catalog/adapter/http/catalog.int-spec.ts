import { v4 as uuidv4 } from 'uuid';
import { startTestApi, type TestApi } from '../../../../../test/kit/api';
import { seedCatalog } from '../../../../../test/kit/catalog';
import { standIn } from '../../../../../test/kit/stand-in';
import { AUDIT_SERVICE } from '../../../audit/contract';
import { DATABASE, type Database } from '../../../../platform/db/database';
import { HEALTH_ROUTES } from '../../../../platform/health/health';
import { checkRoutesAgainstSpec } from '../../../../platform/http/route-spec-check';
import { OPENAPI_DOCUMENT } from '../../../../platform/http/spec-routes';
import { seedId } from '../../app/seed-catalog';
import { CATALOG_SERVICE, type CatalogService } from '../../contract/catalog-service';

const name = { en: 'Cleaning', bn: 'পরিষ্কার' };

describe('catalog API', () => {
  let api: TestApi;
  let customer: string;
  let admin: string;
  let contract: CatalogService;

  beforeAll(async () => {
    // The audit module is ported in parallel; media needs its contract to start.
    const audit = { record: () => Promise.resolve(), listForSubject: () => Promise.resolve([]) };
    api = await startTestApi({ imports: [standIn(new Map([[AUDIT_SERVICE, audit]]))] });
    await seedCatalog(api);
    customer = await api.token(uuidv4(), ['customer']);
    admin = await api.token(uuidv4(), ['catalog_manager']);
    contract = api.app.get(CATALOG_SERVICE, { strict: false });
  });

  it('serves its operations with the spec permissions', () => {
    const report = checkRoutesAgainstSpec(api.app, api.app.get(OPENAPI_DOCUMENT), HEALTH_ROUTES);
    expect(report.mismatched).toEqual([]);
    expect(report.undocumented).toEqual([]);
    const ours = /\/(catalog|services\/)/;
    expect(report.unserved.filter((op) => ours.test(op))).toEqual([]);
  });

  it('lets customers browse, search and open a service', async () => {
    const tree = await api.do('GET', '/v1/customer/catalog', undefined, { token: customer });
    expect(tree.status).toBe(200);
    expect(tree.body?.categories).toHaveLength(5);
    const searches = {
      fan: 'fan-install',
      ফ্যান: 'fan-install',
      plumbr: 'plumber',
      স্যালন: 'home-salon',
    };
    for (const [q, key] of Object.entries(searches)) {
      const path = `/v1/customer/catalog/search?q=${encodeURIComponent(q)}`;
      const r = await api.do('GET', path, undefined, { token: customer });
      const ids = [
        ...(r.body?.services as { id: string }[]),
        ...(r.body?.subServices as { id: string }[]),
      ].map((s) => s.id);
      expect([q, ids]).toEqual([
        q,
        expect.arrayContaining([
          key === 'fan-install' ? seedId('sub-service', key) : seedId('service', key),
        ]),
      ]);
    }
    const electrician = await api.do(
      'GET',
      `/v1/customer/services/${seedId('service', 'electrician')}`,
      undefined,
      { token: customer },
    );
    expect(electrician.status).toBe(200);
    expect(electrician.body?.subServices).toHaveLength(5);
    const unknown = await api.do('GET', `/v1/customer/services/${uuidv4()}`, undefined, {
      token: customer,
    });
    expect(unknown).toMatchObject({ status: 404, code: 'NOT_FOUND' });
    const provider = await api.token(uuidv4(), ['provider']);
    expect(
      (await api.do('GET', '/v1/provider/catalog', undefined, { token: provider })).status,
    ).toBe(200);
  });

  it('lets admins edit the catalog and version prices', async () => {
    const opts = { token: admin };
    const cat = await api.do(
      'POST',
      '/v1/admin/catalog/categories',
      { name, iconKey: 'broom', published: true },
      opts,
    );
    expect(cat.status).toBe(201);
    const categoryId = cat.body?.id as string;
    const serviceBody = {
      categoryId,
      name,
      iconKey: 'broom',
      serviceModel: 'on_demand',
      requiredLevel: 1,
      searchRadiusM: 5000,
      published: true,
      level2Checklist: [name],
    };
    const svc = await api.do('POST', '/v1/admin/catalog/services', serviceBody, opts);
    expect(svc.status).toBe(201);
    const serviceId = svc.body?.id as string;
    const subBody = {
      serviceId,
      name,
      unit: 'job',
      initialPrice: 100_000,
      published: true,
      description: name,
      inclusions: [name],
      exclusions: [],
    };
    const sub = await api.do('POST', '/v1/admin/catalog/sub-services', subBody, opts);
    expect(sub.status).toBe(201);
    const subId = sub.body?.id as string;
    const before = await contract.getPriceSnapshot(subId);
    expect(before.amountPaisa).toBe(100_000);
    const prices = `/v1/admin/catalog/sub-services/${subId}/prices`;
    expect((await api.do('POST', prices, { amount: 120_000 }, opts)).status).toBe(201);
    const after = await contract.getPriceSnapshot(subId);
    expect(after.amountPaisa).toBe(120_000);
    expect(after.priceVersionId).not.toBe(before.priceVersionId);
    const history = await api.do('GET', prices, undefined, opts);
    expect(history.body?.items).toHaveLength(2);
    const updates: [string, unknown][] = [
      [`/v1/admin/catalog/categories/${categoryId}`, { name, iconKey: 'broom', published: false }],
      [`/v1/admin/catalog/services/${serviceId}`, serviceBody],
      [`/v1/admin/catalog/sub-services/${subId}`, subBody],
    ];
    for (const [path, body] of updates) {
      expect([path, (await api.do('PUT', path, body, opts)).status]).toEqual([path, 200]);
    }
    const tree = await api.do('GET', '/v1/admin/catalog', undefined, opts);
    expect(tree.body?.categories).toHaveLength(6);
  });

  it('refuses missing and invalid items', async () => {
    const missing = uuidv4();
    const service = {
      categoryId: missing,
      name,
      iconKey: 'x',
      serviceModel: 'on_demand',
      requiredLevel: 1,
      searchRadiusM: 5000,
    };
    const cases: [string, string, unknown, number][] = [
      ['PUT', `/v1/admin/catalog/categories/${missing}`, { name, iconKey: 'x', sortOrder: 3 }, 404],
      ['PUT', `/v1/admin/catalog/services/${missing}`, service, 404],
      ['POST', '/v1/admin/catalog/services', service, 404],
      ['POST', '/v1/admin/catalog/services', { ...service, requiresLevel2: true }, 422],
      ['POST', '/v1/admin/catalog/sub-services', { serviceId: missing, name, unit: 'job' }, 422],
      [
        'POST',
        '/v1/admin/catalog/sub-services',
        { serviceId: missing, name, unit: 'job', initialPrice: 1 },
        404,
      ],
      [
        'PUT',
        `/v1/admin/catalog/sub-services/${missing}`,
        { serviceId: missing, name, unit: 'job' },
        404,
      ],
      ['POST', `/v1/admin/catalog/sub-services/${missing}/prices`, { amount: 1 }, 404],
      ['GET', `/v1/admin/catalog/sub-services/${missing}/prices`, undefined, 404],
    ];
    for (const [method, path, body, status] of cases) {
      const r = await api.do(method, path, body, { token: admin });
      expect([method, path, r.status]).toEqual([method, path, status]);
    }
    const noPrice = await api.do(
      'POST',
      '/v1/admin/catalog/sub-services',
      { serviceId: missing, name, unit: 'job' },
      { token: admin },
    );
    expect(noPrice.body).toMatchObject({
      error: { code: 'VALIDATION_FAILED', details: { field: 'amount' } },
    });
    await expect(contract.getService(uuidv4())).rejects.toMatchObject({
      reason: 'catalog.service_not_found',
    });
    await expect(contract.getPriceSnapshot(uuidv4())).rejects.toMatchObject({
      reason: 'catalog.sub_service_not_found',
    });
  });

  it('answers the contract from the seeded catalog', async () => {
    const salon = await contract.getService(seedId('service', 'home-salon'));
    expect(salon).toMatchObject({ womenProvidersOnly: true, model: 'on_demand' });
    expect(salon.level2Checklist).toHaveLength(2);
    expect(await contract.listServices()).toHaveLength(5);
  });

  it('answers 500 when the database is gone', async () => {
    await api.do('GET', '/v1/admin/catalog', undefined, { token: admin });
    await api.do('GET', '/v1/customer/catalog', undefined, { token: customer });
    await api.app.get<symbol, Database>(DATABASE).close();
    const id = uuidv4();
    const category = { name: { en: 'A', bn: 'B' }, iconKey: 'x' };
    const calls: [string, string, string, unknown][] = [
      ['GET', '/v1/customer/catalog', customer, undefined],
      ['GET', '/v1/provider/catalog', customer, undefined],
      ['GET', '/v1/admin/catalog', admin, undefined],
      ['GET', '/v1/customer/catalog/search?q=fan', customer, undefined],
      ['GET', `/v1/customer/services/${id}`, customer, undefined],
      ['POST', '/v1/admin/catalog/categories', admin, category],
      ['PUT', `/v1/admin/catalog/categories/${id}`, admin, category],
      ['GET', `/v1/admin/catalog/sub-services/${id}/prices`, admin, undefined],
    ];
    for (const [method, path, token, body] of calls) {
      const r = await api.do(method, path, body, { token });
      expect([method, path, r.status]).toEqual([method, path, 500]);
    }
  });
});
