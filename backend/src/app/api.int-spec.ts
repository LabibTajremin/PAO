import { v4 as uuidv4 } from 'uuid';
import { startTestApi, type TestApi } from '../../test/kit/api';
import { RATE_LIMITS } from '../platform/http/guards';
import { DOCUMENT_EXPIRY, PUSH_CAPTURE, SMS_CAPTURE } from '../platform/testing/test-hooks';

describe('API without business modules', () => {
  let api: TestApi;
  let customer: string;

  beforeAll(async () => {
    api = await startTestApi({
      override: (b) =>
        b.overrideProvider(RATE_LIMITS).useValue({ perUser: 3, perIp: 2, windowMs: 60_000 }),
    });
    customer = await api.token(uuidv4(), ['customer']);
  });

  it('answers liveness and readiness', async () => {
    expect(await api.do('GET', '/healthz')).toMatchObject({ status: 200, body: { status: 'ok' } });
    expect(await api.do('GET', '/readyz')).toMatchObject({ status: 200, body: { status: 'ok' } });
  });

  it('answers unknown routes and wrong methods like the Go API', async () => {
    const unknown = await api.do('GET', '/v1/nope', undefined, { token: customer });
    expect(unknown.status).toBe(404);
    expect(unknown.text).toBe('{"error":{"code":"NOT_FOUND","message":"Not found."}}\n');
    const method = await api.do('DELETE', '/v1/customer/catalog');
    expect(method.status).toBe(405);
    expect(method.body).toEqual({ error: { code: 'NOT_FOUND', message: 'Method not allowed.' } });
    expect((await api.do('DELETE', '/healthz')).status).toBe(405);
  });

  it('denies an operation the caller has no permission for', async () => {
    const forbidden = await api.do('GET', '/v1/admin/dashboard', undefined, { token: customer });
    expect(forbidden).toMatchObject({ status: 403, code: 'FORBIDDEN' });
    expect(forbidden.body).toMatchObject({ error: { details: { permission: 'dashboard:read' } } });
  });

  it('tells an expired token from an invalid one', async () => {
    const token = await api.token(uuidv4(), ['customer']);
    api.clock.advance(16 * 60_000);
    const expired = await api.do('GET', '/v1/me', undefined, { token });
    expect(expired).toMatchObject({ status: 401, code: 'TOKEN_EXPIRED' });
    expect((await api.do('GET', '/v1/me', undefined, { token: 'garbage' })).code).toBe(
      'UNAUTHENTICATED',
    );
    api.clock.advance(-16 * 60_000);
  });

  it('validates requests against the contract after authentication', async () => {
    const r = await api.do('POST', '/v1/auth/otp/request', { phone: '123' });
    expect(r).toMatchObject({ status: 422, code: 'VALIDATION_FAILED' });
    expect(r.text).toContain('body/phone');
    const bad = await api.do('POST', '/v1/auth/otp/request', '{', { raw: true });
    expect(bad.code).toBe('VALIDATION_FAILED');
    const query = await api.do('GET', '/v1/customer/bookings?limit=x', undefined, {
      token: customer,
    });
    expect(query.code).toBe('VALIDATION_FAILED');
  });

  it('limits anonymous calls per IP with Retry-After', async () => {
    const path = '/v1/auth/admin/login';
    const body = { email: 'a@pao.bd', password: 'correct horse battery' };
    expect((await api.do('POST', path, body)).code).toBe('INVALID_CREDENTIALS');
    expect((await api.do('POST', path, body)).code).toBe('INVALID_CREDENTIALS');
    const limited = await api.do('POST', path, body);
    expect(limited).toMatchObject({ status: 429, code: 'RATE_LIMITED' });
    expect(limited.headers.get('retry-after')).toBe('60');
  });

  it('sets security headers, a request id and CORS for the admin origin', async () => {
    const r = await api.do('GET', '/healthz', undefined, {
      headers: { Origin: 'http://admin', 'X-Request-ID': 'client-req-123' },
    });
    expect(r.headers.get('x-content-type-options')).toBe('nosniff');
    expect(r.headers.get('x-frame-options')).toBe('DENY');
    expect(r.headers.get('strict-transport-security')).toContain('max-age=31536000');
    expect(r.headers.get('x-request-id')).toBe('client-req-123');
    expect(r.headers.get('access-control-allow-origin')).toBe('http://admin');
    expect(r.headers.get('access-control-allow-credentials')).toBe('true');
    const preflight = await fetch(`${api.url}/v1/admin/dashboard`, {
      method: 'OPTIONS',
      headers: { Origin: 'http://admin', 'Access-Control-Request-Method': 'GET' },
    });
    expect(preflight.status).toBe(204);
    const foreign = await api.do('GET', '/healthz', undefined, {
      headers: { Origin: 'https://evil.example' },
    });
    expect(foreign.headers.get('access-control-allow-origin')).toBeNull();
    expect(foreign.headers.get('x-request-id')).toHaveLength(36);
  });

  it('serves the test hooks with the modules wired so far', async () => {
    expect((await api.do('GET', '/__test/sms?phone=01712345601')).status).toBe(404);
    expect((await api.do('GET', '/__test/pushes?token=x')).body).toEqual({ pushes: [] });
    expect((await api.do('POST', '/__test/verification/expire?at=yesterday')).status).toBe(400);
    const at = new Date().toISOString();
    // Verification provides the expiry seam; nothing has expired in a fresh database.
    expect((await api.do('POST', `/__test/verification/expire?at=${at}`)).status).toBe(204);
  });
});

describe('API test hooks with module seams', () => {
  it('read the captures and run the expiry sweep', async () => {
    const expired: Date[] = [];
    const api = await startTestApi({
      // Identity, notification and verification provide the real seams; these stand-ins replace them.
      override: (b) =>
        b
          .overrideProvider(SMS_CAPTURE)
          .useValue({
            normalizePhone: (raw: string) => (raw.length === 11 ? `+88${raw}` : undefined),
            last: (phone: string) =>
              phone === '+8801712345601' ? 'Your PAO code is 123456' : undefined,
          })
          .overrideProvider(PUSH_CAPTURE)
          .useValue({ sentTo: () => [{ title: 'New request', body: '', data: { type: 'x' } }] })
          .overrideProvider(DOCUMENT_EXPIRY)
          .useValue({
            expireDocumentsAt: (at: Date) => {
              expired.push(at);
              return expired.length > 1 ? Promise.reject(new Error('db down')) : Promise.resolve();
            },
          }),
    });
    expect((await api.do('GET', '/__test/sms?phone=01712345601')).body).toEqual({
      message: 'Your PAO code is 123456',
    });
    expect((await api.do('GET', '/__test/sms?phone=123')).status).toBe(400);
    expect((await api.do('GET', '/__test/sms?phone=01712345609')).status).toBe(404);
    expect((await api.do('GET', '/__test/pushes?token=t')).body).toEqual({
      pushes: [{ title: 'New request', body: '', data: { type: 'x' } }],
    });
    const path = '/__test/verification/expire?at=2036-01-01T00:00:00Z';
    expect((await api.do('POST', path)).status).toBe(204);
    expect(expired[0]?.toISOString()).toBe('2036-01-01T00:00:00.000Z');
    const failed = await api.do('POST', path);
    expect(failed).toMatchObject({ status: 500, text: 'db down\n' });
  });

  it('answer 501 for the expiry sweep when no module provides it', async () => {
    const api = await startTestApi({
      override: (b) => b.overrideProvider(DOCUMENT_EXPIRY).useValue(null),
    });
    const at = new Date().toISOString();
    expect((await api.do('POST', `/__test/verification/expire?at=${at}`)).status).toBe(501);
  });

  it('are absent outside APP_ENV=test', async () => {
    const api = await startTestApi({ config: { appEnv: 'dev' } });
    const r = await api.do('GET', '/__test/sms?phone=01712345601');
    expect(r).toMatchObject({ status: 404, code: 'NOT_FOUND' });
  });
});
