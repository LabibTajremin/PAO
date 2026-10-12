import { v7 as uuid } from 'uuid';
import { startTestApi, type TestApi, type TestResponse } from '../../../../../test/kit/api';
import { adminSession, signIn } from '../../../../../test/kit/identity';
import { HEALTH_ROUTES } from '../../../../platform/health/health';
import { checkRoutesAgainstSpec } from '../../../../platform/http/route-spec-check';
import { OPENAPI_DOCUMENT } from '../../../../platform/http/spec-routes';
import { CUSTOMER_SERVICE, type CustomerService } from '../../contract';

const PHONE = '01712345678';
const profile = { name: 'Nusrat Jahan', language: 'bn' };

/** An address body like the Go integration tests send. */
function address(label: string, isDefault: boolean): Record<string, unknown> {
  return {
    label,
    line1: 'House 12, Road 5',
    line2: 'Block C',
    area: 'Banani',
    location: { lat: 23.7937, lng: 90.4066 },
    isDefault,
  };
}

async function add(api: TestApi, token: string, body: unknown) {
  return (await api.do('POST', '/v1/customer/addresses', body, { token })).body as {
    id: string;
  };
}

function ids(r: TestResponse): { all: string[]; def: string | undefined } {
  const items = (r.body?.items ?? []) as { id: string; isDefault: boolean }[];
  return { all: items.map((i) => i.id), def: items.find((i) => i.isDefault)?.id };
}

describe('customer addresses', () => {
  let api: TestApi;
  let customers: CustomerService;

  beforeAll(async () => {
    api = await startTestApi();
    customers = api.app.get(CUSTOMER_SERVICE);
  });

  it('serves every customer operation of the spec with its permission', () => {
    const report = checkRoutesAgainstSpec(api.app, api.app.get(OPENAPI_DOCUMENT), HEALTH_ROUTES);
    expect(report.mismatched).toEqual([]);
    expect(report.undocumented).toEqual([]);
    const own = /\/v1\/customer\/(profile|addresses|service-area)/;
    expect(report.unserved.filter((op) => own.test(op))).toEqual([]);
  });

  // TestAddresses_DefaultsLimitAndOwnership
  it('switches defaults, promotes the newest, caps at ten and hides others', async () => {
    const tp = await signIn(api, PHONE, 'customer');
    const token = tp.accessToken;
    await api.do('PUT', '/v1/customer/profile', profile, { token });
    const first = await add(api, token, address('home', false));
    expect(first).toMatchObject({ isDefault: true, location: { lat: 23.7937 } });
    const second = await add(api, token, address('office', true));
    let list = ids(await api.do('GET', '/v1/customer/addresses', undefined, { token }));
    expect(list.all).toHaveLength(2);
    expect(list.def).toBe(second.id);

    const path = `/v1/customer/addresses/${first.id}`;
    const edit = { ...address('other', true), line1: 'House 14, Road 7' };
    const edited = await api.do('PUT', path, edit, { token });
    expect(edited).toMatchObject({
      status: 200,
      body: { isDefault: true, line1: 'House 14, Road 7' },
    });
    const back = await api.do('POST', `/v1/customer/addresses/${second.id}/default`, undefined, {
      token,
    });
    expect(back.body?.isDefault).toBe(true);
    expect((await api.do('PUT', path, address('home', false), { token })).body?.isDefault).toBe(
      false,
    );
    expect((await api.do('DELETE', path, undefined, { token })).status).toBe(204);

    const third = await add(api, token, address('home', false));
    await api.do('DELETE', `/v1/customer/addresses/${second.id}`, undefined, { token });
    list = ids(await api.do('GET', '/v1/customer/addresses', undefined, { token }));
    expect(list.def).toBe(third.id);
    for (let i = 0; i < 9; i++) {
      await api.do('POST', '/v1/customer/addresses', address('other', false), { token });
    }
    const eleventh = await api.do('POST', '/v1/customer/addresses', address('other', false), {
      token,
    });
    expect(eleventh.code).toBe('ADDRESS_LIMIT_REACHED');

    const got = await customers.getAddress(tp.account.id, third.id);
    expect(got).toMatchObject({ area: 'Banani', location: { lng: 90.4066 } });

    const stranger = (await signIn(api, '01912345679', 'customer')).accessToken;
    await api.do('PUT', '/v1/customer/profile', profile, { token: stranger });
    const thirdPath = `/v1/customer/addresses/${third.id}`;
    const tries: [string, string, unknown][] = [
      ['PUT', thirdPath, address('home', false)],
      ['DELETE', thirdPath, undefined],
      ['POST', `${thirdPath}/default`, undefined],
    ];
    for (const [method, p, body] of tries) {
      expect((await api.do(method, p, body, { token: stranger })).status).toBe(404);
    }
  });

  // TestAddresses_ValidationAndServiceArea
  it('validates pins and checks the launch area', async () => {
    const root = await adminSession(api, ['super_admin']);
    const token = (await signIn(api, '01812345670', 'customer')).accessToken;
    await api.do('PUT', '/v1/customer/profile', profile, { token });
    const abroad = { ...address('home', false), location: { lat: 51.5, lng: -0.12 } };
    expect((await api.do('POST', '/v1/customer/addresses', abroad, { token })).code).toBe(
      'OUTSIDE_SERVICE_AREA',
    );
    const unknown = await api.do(
      'PUT',
      `/v1/customer/addresses/${uuid()}`,
      address('home', false),
      { token },
    );
    expect(unknown.status).toBe(404);
    const noLines = { label: 'home', line1: 'Road 5', location: { lat: 23.8, lng: 90.4 } };
    const plain = await api.do('POST', '/v1/customer/addresses', noLines, { token });
    expect(plain).toMatchObject({ status: 201, body: { line2: '' } });

    const area =
      '{"type":"Polygon","coordinates":[[[90.3,23.7],[90.5,23.7],[90.5,23.9],[90.3,23.9],[90.3,23.7]]]}';
    const set = await api.do(
      'PUT',
      '/v1/admin/settings/service_area.geojson',
      { value: area },
      {
        token: root.accessToken,
      },
    );
    expect(set.status).toBe(200);
    const inside = await api.do('GET', '/v1/customer/service-area?lat=23.8&lng=90.4', undefined, {
      token,
    });
    expect(inside.body?.covered).toBe(true);
    expect(await customers.isInServiceArea({ lat: 22.3, lng: 91.8 })).toBe(false);
  });
});
