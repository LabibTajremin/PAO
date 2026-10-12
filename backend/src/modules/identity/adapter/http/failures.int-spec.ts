import { randomUUID } from 'node:crypto';
import type Redis from 'ioredis';
import { startTestApi, type TestApi } from '../../../../../test/kit/api';
import { adminSession, lastCode, signIn } from '../../../../../test/kit/identity';
import { DATABASE, type Database } from '../../../../platform/db/database';
import { isDomainError } from '../../../../platform/errors/domain-error';
import { ADMIN_SEEDER, type AdminSeeder } from '../../../../platform/seeding/seeders';
import { REDIS } from '../../../../platform/redis/redis-client';
import { IDENTITY_SERVICE, IdentityErrors, type IdentityService } from '../../contract';
import { SMS_SENDER } from '../../port/outside-world';
import { ConsoleSms, SslWirelessSms } from '../sms/sms-senders';

const PHONE = '01712345678';

const reason = (p: Promise<unknown>) =>
  p.then(
    () => 'resolved',
    (e: unknown) => (e instanceof Error && 'reason' in e ? (e as { reason: string }).reason : e),
  );

describe('identity contract in process', () => {
  it('reads accounts and roles, changes status and checks other-purpose codes', async () => {
    const api = await startTestApi();
    const c = api.app.get<IdentityService>(IDENTITY_SERVICE);
    const tp = await signIn(api, PHONE, 'customer');
    const acc = await c.getAccount(tp.account.id);
    expect(acc).toMatchObject({ phone: '+8801712345678', roles: ['customer'], status: 'active' });
    expect(await c.hasRole(tp.account.id, 'provider')).toBe(false);
    expect(await reason(c.getAccount(randomUUID()))).toBe(IdentityErrors.AccountNotFound);
    expect(await reason(c.hasRole(randomUUID(), 'provider'))).toBe(IdentityErrors.AccountNotFound);
    const set = (status: 'active' | 'banned') =>
      c.setAccountStatus({ accountId: tp.account.id, status, reason: 'appeal', actorId: null });
    expect(await reason(set('active'))).toBe(IdentityErrors.StatusInvalid);
    await set('banned');
    await expect(set('active')).resolves.toMatchObject({ status: 'active' });
    await c.sendPhoneCode('01912345678', 'emergency_contact');
    const wrong = await c
      .checkPhoneCode('01912345678', 'emergency_contact', 'x')
      .catch((e: unknown) => e);
    expect(isDomainError(wrong, IdentityErrors.CodeInvalid)).toBe(true);
    const code = lastCode(api, '01912345678');
    await expect(c.checkPhoneCode('01912345678', 'emergency_contact', code)).resolves.toBe(
      undefined,
    );
  });
});

describe('admin seeder', () => {
  it('creates a demo admin who can log in with the seed password', async () => {
    const api = await startTestApi();
    const seeder = api.app.get<AdminSeeder>(ADMIN_SEEDER, { strict: false });
    const admin = { email: 'super@pao.bd', name: 'Super', roles: ['super_admin'] };
    await seeder.ensureAdmin(admin, 'demo password 123');
    await seeder.ensureAdmin(admin, 'demo password 123');
    const r = await api.do('POST', '/v1/auth/admin/login', {
      email: 'super@pao.bd',
      password: 'demo password 123',
    });
    expect(r.body).toMatchObject({ mustChangePassword: false });
  });
});

describe('identity endpoints at the edges', () => {
  let api: TestApi;

  beforeEach(async () => {
    api = await startTestApi();
  });

  it('answers a role-less account and a deletion without a code', async () => {
    const customer = await signIn(api, PHONE, 'customer');
    const token = customer.accessToken;
    await api.app
      .get<Database>(DATABASE)
      .query('DELETE FROM identity.account_roles WHERE account_id = $1', [customer.account.id]);
    const r = await api.do('GET', '/v1/me/permissions', undefined, { token });
    expect(r.body).toMatchObject({ permissions: [], screens: [] });
    const del = await api.do('DELETE', '/v1/me', { code: '123456' }, { token });
    expect(del.code).toBe('OTP_EXPIRED');
  });

  it('answers 500 when the database is gone', async () => {
    const superAdmin = await adminSession(api, ['super_admin']);
    const customer = await signIn(api, PHONE, 'customer');
    const admin = superAdmin.accessToken;
    // Warm the RBAC cache so authorisation passes and the handlers meet the failure.
    await api.do('GET', '/v1/admin/roles', undefined, { token: admin });
    await api.app.get<Database>(DATABASE).close();
    const calls: [string, string, string, unknown][] = [
      ['GET', '/v1/me', customer.accessToken, undefined],
      ['GET', '/v1/me/permissions', customer.accessToken, undefined],
      ['DELETE', '/v1/me', customer.accessToken, { code: '123456' }],
      ['GET', '/v1/admin/admin-users', admin, undefined],
      [
        'POST',
        '/v1/admin/admin-users',
        admin,
        { email: 'x@pao.bd', name: 'Xavier', roles: ['verifier'] },
      ],
      ['PATCH', `/v1/admin/admin-users/${superAdmin.id}`, admin, { active: true }],
      ['GET', '/v1/admin/roles', admin, undefined],
      ['PUT', '/v1/admin/roles/verifier', admin, { permissions: [], screens: [] }],
      ['POST', '/v1/auth/admin/login', '', { email: superAdmin.email, password: 'whatever12' }],
      [
        'POST',
        '/v1/auth/admin/password',
        admin,
        { currentPassword: 'whatever12', newPassword: 'a much longer passphrase 1' },
      ],
    ];
    for (const [method, path, token, body] of calls) {
      const opts = token === '' ? { unchecked: true } : { token, unchecked: true };
      expect([method, path, (await api.do(method, path, body, opts)).status]).toEqual([
        method,
        path,
        500,
      ]);
    }
  });

  it('answers 500 when Redis is gone', async () => {
    const customer = await signIn(api, PHONE, 'customer');
    api.app.get<Redis>(REDIS).disconnect();
    const token = customer.accessToken;
    for (const [method, path] of [
      ['POST', '/v1/auth/logout'],
      ['GET', '/v1/me'],
    ] as const) {
      const body = method === 'GET' ? undefined : {};
      expect((await api.do(method, path, body, { token, unchecked: true })).status).toBe(500);
    }
    const body = {
      phone: PHONE,
      code: '123456',
      app: 'customer',
      refreshToken: `${randomUUID()}.x`,
      challengeId: randomUUID(),
    };
    for (const path of ['otp/request', 'otp/verify', 'refresh', 'admin/totp']) {
      const r = await api.do('POST', `/v1/auth/${path}`, body, { unchecked: true });
      expect([path, r.status]).toEqual([path, 500]);
    }
  });

  it('answers 500 when a session entry is corrupt', async () => {
    const tp = await signIn(api, PHONE, 'customer');
    const sid = randomUUID();
    await api.app.get<Redis>(REDIS).set(api.keys.key('rt', sid), 'not-a-hash');
    const token = await api.token(tp.account.id, ['customer'], sid);
    const r = await api.do('POST', '/v1/auth/logout', {}, { token, unchecked: true });
    expect(r.status).toBe(500);
  });
});

describe('SMS adapter choice', () => {
  it('uses the console outside tests and SSL Wireless when configured', async () => {
    const dev = await startTestApi({ config: { appEnv: 'dev' } });
    expect(dev.app.get(SMS_SENDER, { strict: false })).toBeInstanceOf(ConsoleSms);
    const prod = await startTestApi({
      config: {
        appEnv: 'dev',
        smsAdapter: 'sslwireless',
        sslWireless: { apiToken: 't', sid: 's' },
      },
    });
    expect(prod.app.get(SMS_SENDER, { strict: false })).toBeInstanceOf(SslWirelessSms);
  });
});
