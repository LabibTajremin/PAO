import { randomUUID } from 'node:crypto';
import { startTestApi, type TestApi } from '../../../../../test/kit/api';
import { adminSession, signIn } from '../../../../../test/kit/identity';
import { totpCode } from '../../../../platform/auth/totp';

const NEW_PASSWORD = 'a much longer passphrase 1';

describe('admin sign-in and admin screens', () => {
  let api: TestApi;

  beforeEach(async () => {
    api = await startTestApi();
  });

  it('refreshes by cookie, changes the password and logs out clearing the cookie', async () => {
    const s = await adminSession(api, ['super_admin']);
    const cookie = { Cookie: s.refreshCookie };
    const r = await api.do('POST', '/v1/auth/refresh', undefined, { headers: cookie });
    expect(r.status).toBe(200);
    expect(r.body?.refreshToken).toBeUndefined();
    expect(r.headers.get('set-cookie')).toContain('HttpOnly');
    const token = (r.body as { accessToken: string }).accessToken;
    const pw = { currentPassword: s.password, newPassword: NEW_PASSWORD };
    expect((await api.do('POST', '/v1/auth/admin/password', pw, { token })).status).toBe(204);
    const again = await api.do('POST', '/v1/auth/admin/password', pw, { token });
    expect(again.code).toBe('INVALID_CREDENTIALS');
    const login = await api.do('POST', '/v1/auth/admin/login', {
      email: s.email,
      password: NEW_PASSWORD,
    });
    expect(login.body).toMatchObject({ mustChangePassword: false });
    expect(login.body?.totpEnrolment).toBeUndefined();
    const challengeId = login.body?.challengeId as string;
    const wrong = await api.do('POST', '/v1/auth/admin/totp', { challengeId, code: '000000' });
    expect(wrong.code).toBe('TOTP_INVALID');
    const code = await totpCode(s.totpSecret, api.clock.now());
    const ok = await api.do('POST', '/v1/auth/admin/totp', { challengeId, code });
    expect(ok.status).toBe(200);
    const out = await api.do('POST', '/v1/auth/logout', {}, { token, headers: cookie });
    expect(out.status).toBe(204);
    expect(out.headers.get('set-cookie')).toContain('Max-Age=0');
  });

  it('locks out after five wrong passwords and expires unknown challenges', async () => {
    const s = await adminSession(api, ['verifier']);
    for (let i = 0; i < 5; i++) {
      await api.do('POST', '/v1/auth/admin/login', { email: s.email, password: 'wrong-password' });
    }
    const locked = await api.do('POST', '/v1/auth/admin/login', {
      email: s.email,
      password: s.password,
    });
    expect(locked).toMatchObject({ status: 429, code: 'ACCOUNT_LOCKED' });
    const unknown = await api.do('POST', '/v1/auth/admin/totp', {
      challengeId: randomUUID(),
      code: '123456',
    });
    expect(unknown.code).toBe('MFA_CHALLENGE_EXPIRED');
  });

  it('invites, updates and lists admins and edits roles', async () => {
    const token = (await adminSession(api, ['super_admin'])).accessToken;
    const invite = { email: 'support@pao.bd', name: 'Support', roles: ['support_agent'] };
    const r = await api.do('POST', '/v1/admin/admin-users', invite, { token });
    expect(r.status).toBe(201);
    expect(r.body?.temporaryPassword).not.toBe('');
    expect((await api.do('POST', '/v1/admin/admin-users', invite, { token })).status).toBe(409);
    const id = (r.body?.user as { id: string }).id;
    const patch = await api.do(
      'PATCH',
      `/v1/admin/admin-users/${id}`,
      { active: false, roles: ['verifier'] },
      { token },
    );
    expect(patch.body).toMatchObject({ active: false, roles: ['verifier'] });
    const list = await api.do('GET', '/v1/admin/admin-users', undefined, { token });
    expect(list.body?.items).toHaveLength(2);
    const roles = await api.do('GET', '/v1/admin/roles', undefined, { token });
    expect(roles.body?.items).toHaveLength(6);
    const update = {
      permissions: ['verification:review', 'dashboard:read'],
      screens: ['A01', 'A05'],
    };
    expect((await api.do('PUT', '/v1/admin/roles/verifier', update, { token })).status).toBe(200);
    const bad = { permissions: ['made:up'], screens: [] };
    expect((await api.do('PUT', '/v1/admin/roles/verifier', bad, { token })).code).toBe(
      'ROLE_INVALID',
    );
    const customer = await signIn(api, '01812345678', 'customer');
    const forbidden = await api.do('GET', '/v1/admin/roles', undefined, {
      token: customer.accessToken,
    });
    expect(forbidden.status).toBe(403);
  });

  it('answers 404 to a customer changing an admin password', async () => {
    const customer = await signIn(api, '01712345678', 'customer');
    const r = await api.do(
      'POST',
      '/v1/auth/admin/password',
      { currentPassword: 'whatever1', newPassword: NEW_PASSWORD },
      // The Go API answered 404 here, which the contract does not list.
      { token: customer.accessToken, unchecked: true },
    );
    expect(r.status).toBe(404);
  });
});
