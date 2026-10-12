import { startTestApi, type TestApi } from '../../test/kit/api';
import { HEALTH_ROUTES } from '../platform/health/health';
import { OPENAPI_DOCUMENT } from '../platform/http/spec-routes';
import { checkRoutesAgainstSpec } from '../platform/http/route-spec-check';

describe('the composed API', () => {
  let api: TestApi;

  beforeAll(async () => {
    api = await startTestApi();
  });

  it('serves every contract operation, leaving nothing to the 501 catch-all', () => {
    const report = checkRoutesAgainstSpec(api.app, api.app.get(OPENAPI_DOCUMENT), HEALTH_ROUTES);
    expect(report).toEqual({ mismatched: [], undocumented: [], unserved: [] });
  });
});
