import { startTestApi, type TestApi } from './api';
import { accountToken, adminSession, lastCode, signIn, signInAgain } from './identity';

describe('identity test kit', () => {
  let api: TestApi;

  beforeAll(async () => {
    api = await startTestApi();
  });

  it('signs in by phone, again after the resend timer, and signs real-account tokens', async () => {
    const first = await signIn(api, '01712345678', 'customer');
    expect(first).toMatchObject({ isNewAccount: true, account: { roles: ['customer'] } });
    expect(lastCode(api, '+8801712345678')).toMatch(/^\d{6}$/);
    const again = await signInAgain(api, '01712345678', 'partner');
    expect(again.account.roles).toEqual(['customer', 'provider']);
    const token = await accountToken(api, first.account.id);
    const me = await api.do('GET', '/v1/me', undefined, { token });
    expect(me.body).toMatchObject({ id: first.account.id, roles: ['customer', 'provider'] });
  });

  it('reports a sign-in the API refuses', async () => {
    await expect(signIn(api, '01712345678', 'customer')).rejects.toThrow('otp request: 429');
    expect(() => lastCode(api, '01999999999')).toThrow('no code sent');
  });

  it('signs an admin in through password and TOTP', async () => {
    const admin = await adminSession(api, ['super_admin']);
    expect(admin.refreshCookie).toMatch(/^pao_refresh=/);
    expect(admin.totpSecret).not.toBe('');
    const r = await api.do('GET', '/v1/admin/roles', undefined, { token: admin.accessToken });
    expect(r.status).toBe(200);
    await expect(adminSession(api, ['customer'])).rejects.toThrow();
  });
});
