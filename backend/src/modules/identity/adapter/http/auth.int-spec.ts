import { startTestApi, type TestApi } from '../../../../../test/kit/api';
import { lastCode, signIn, signInAgain } from '../../../../../test/kit/identity';
import { checkRoutesAgainstSpec } from '../../../../platform/http/route-spec-check';
import { OPENAPI_DOCUMENT } from '../../../../platform/http/spec-routes';
import { HEALTH_ROUTES } from '../../../../platform/health/health';
import { IDENTITY_SERVICE, type IdentityService } from '../../contract';
import { VERIFICATION_SERVICE } from '../../../verification/contract';

const PHONE = '01712345678';

/** Verification is not ported yet; a provider without verification is at Level 0. */
const levelZero = {
  provide: VERIFICATION_SERVICE,
  useValue: { getLevel: () => Promise.resolve(0) },
};

describe('identity HTTP routes', () => {
  let api: TestApi;

  beforeEach(async () => {
    api = await startTestApi({ providers: [levelZero] });
  });

  it('serves every identity operation with the spec permission', () => {
    const report = checkRoutesAgainstSpec(api.app, api.app.get(OPENAPI_DOCUMENT), HEALTH_ROUTES);
    expect(report.mismatched).toEqual([]);
    expect(report.undocumented).toEqual([]);
    const mine = /\/v1\/(auth\/|me\b|admin\/(admin-users|roles))/;
    expect(report.unserved.filter((op) => mine.test(op))).toEqual([]);
  });

  it('signs in by OTP, refreshes, detects reuse and logs out', async () => {
    const tp = await signIn(api, PHONE, 'customer');
    expect(tp).toMatchObject({ isNewAccount: true, account: { roles: ['customer'] } });
    const me = await api.do('GET', '/v1/me', undefined, { token: tp.accessToken });
    expect(me.body).toMatchObject({ phone: '+8801712345678' });
    const r = await api.do('POST', '/v1/auth/refresh', { refreshToken: tp.refreshToken });
    expect(r.status).toBe(200);
    const next = r.body as { refreshToken: string };
    expect(next.refreshToken).not.toBe(tp.refreshToken);
    const reuse = await api.do('POST', '/v1/auth/refresh', { refreshToken: tp.refreshToken });
    expect(reuse).toMatchObject({ status: 401, code: 'REFRESH_TOKEN_INVALID' });
    const after = await api.do('POST', '/v1/auth/refresh', { refreshToken: next.refreshToken });
    expect(after.status).toBe(401);
    const fresh = await signInAgain(api, PHONE, 'customer');
    const out = await api.do(
      'POST',
      '/v1/auth/logout',
      { allDevices: false },
      { token: fresh.accessToken },
    );
    expect(out.status).toBe(204);
    expect((await api.do('GET', '/v1/me', undefined, { token: fresh.accessToken })).status).toBe(
      401,
    );
  });

  it('validates phones, throttles resends and locks out wrong codes', async () => {
    expect((await api.do('POST', '/v1/auth/otp/request', { phone: '123' })).status).toBe(422);
    const first = await api.do('POST', '/v1/auth/otp/request', { phone: PHONE });
    expect(first.body).toEqual({ expiresInSeconds: 300, resendAfterSeconds: 60 });
    const again = await api.do('POST', '/v1/auth/otp/request', { phone: PHONE });
    expect(again).toMatchObject({ status: 429, code: 'RATE_LIMITED' });
    expect(again.headers.get('retry-after')).not.toBeNull();
    const code = lastCode(api, PHONE);
    const wrong = code === '000000' ? '111111' : '000000';
    const verify = (phone: string, c: string) =>
      api.do('POST', '/v1/auth/otp/verify', { phone, code: c, app: 'customer' });
    expect(await verify(PHONE, wrong)).toMatchObject({ status: 401, code: 'OTP_INVALID' });
    expect((await verify('01812345678', '123456')).code).toBe('OTP_EXPIRED');
    for (let i = 0; i < 3; i++) {
      await verify(PHONE, wrong);
    }
    const locked = await verify(PHONE, wrong);
    expect(locked).toMatchObject({ status: 429, code: 'OTP_LOCKED' });
    expect(locked.headers.get('retry-after')).toBe('300');
    expect((await verify(PHONE, code)).code).toBe('OTP_EXPIRED');
  });

  it('gates a Level 0 provider to the onboarding screens', async () => {
    const tp = await signIn(api, PHONE, 'partner');
    const r = await api.do('GET', '/v1/me/permissions', undefined, { token: tp.accessToken });
    expect(r.body).toMatchObject({ providerGate: true, roles: ['provider'] });
    expect((r.body as { screens: string[] }).screens).toHaveLength(14);
  });

  it('shuts a banned account out', async () => {
    const tp = await signIn(api, PHONE, 'customer');
    await api.app.get<IdentityService>(IDENTITY_SERVICE).setAccountStatus({
      accountId: tp.account.id,
      status: 'banned',
      reason: 'fraud',
      actorId: null,
    });
    expect((await api.do('GET', '/v1/me', undefined, { token: tp.accessToken })).status).toBe(401);
    const refresh = await api.do('POST', '/v1/auth/refresh', { refreshToken: tp.refreshToken });
    expect(refresh.status).toBe(401);
    const code = await api.do('POST', '/v1/auth/otp/request', { phone: PHONE });
    expect(code).toMatchObject({ status: 403, code: 'ACCOUNT_BANNED' });
  });

  it('deletes the account after a fresh code', async () => {
    const tp = await signIn(api, PHONE, 'customer');
    api.clock.advance(60_000);
    const sent = await api.do('POST', '/v1/auth/otp/request', {
      phone: PHONE,
      purpose: 'delete_account',
    });
    expect(sent.status).toBe(202);
    const del = await api.do(
      'DELETE',
      '/v1/me',
      { code: lastCode(api, PHONE) },
      { token: tp.accessToken },
    );
    expect(del.status).toBe(204);
    expect((await api.do('GET', '/v1/me', undefined, { token: tp.accessToken })).status).toBe(401);
    const refresh = await api.do('POST', '/v1/auth/refresh', { refreshToken: tp.refreshToken });
    expect(refresh.status).toBe(401);
  });
});
