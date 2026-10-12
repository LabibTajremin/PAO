import { HashMalformedError } from '../../../platform/auth/password-hash';
import { DomainError } from '../../../platform/errors/domain-error';
import { boom } from '../../../../test/fakes/identity';
import { harness } from '../../../../test/fakes/identity-harness';
import { ADMIN_MAX_FAILURES, CHALLENGE_ATTEMPTS } from '../domain/admin';
import { IdentityReasons } from '../domain/reasons';

const outcome = (p: Promise<unknown>) =>
  p.then(
    () => 'resolved',
    (e: unknown) => (e instanceof DomainError ? e.reason : e),
  );

const EMAIL = 'verifier@pao.bd';
const NEW_PASSWORD = 'a much longer passphrase 1';

describe('admin sign-in', () => {
  it('enrols TOTP on the first login, then logs in with the stored secret', async () => {
    const h = harness();
    const { admin, temporaryPassword } = await h.newAdmin();
    const ch = await h.adminSignIn.login(EMAIL, temporaryPassword);
    expect(ch).toMatchObject({ mustChangePassword: true });
    expect(ch.enrolSecret).not.toBe('');
    expect(ch.enrolUrl).toContain('otpauth://');
    const s = await h.adminTotp.verify(ch.id, await h.totp(ch.enrolSecret));
    expect(s.account.id).toBe(admin.id);
    expect(h.repo.admins.get(admin.id)?.totpEnrolled).toBe(true);
    await h.adminSignIn.changePassword(admin.id, temporaryPassword, NEW_PASSWORD);
    const again = await h.adminSignIn.login(EMAIL, NEW_PASSWORD);
    expect(again).toMatchObject({ enrolSecret: '', mustChangePassword: false });
    await expect(h.adminTotp.verify(again.id, await h.totp(ch.enrolSecret))).resolves.toBeDefined();
  });

  it('locks an admin out after five wrong passwords', async () => {
    const h = harness();
    await h.newAdmin();
    expect(await outcome(h.adminSignIn.login('nobody@pao.bd', 'x'))).toBe(
      IdentityReasons.InvalidCredentials,
    );
    for (let i = 0; i < ADMIN_MAX_FAILURES; i++) {
      expect(await outcome(h.adminSignIn.login(EMAIL, 'wrong'))).toBe(
        IdentityReasons.InvalidCredentials,
      );
    }
    expect(await outcome(h.adminSignIn.login(EMAIL, 'wrong'))).toBe(IdentityReasons.AdminLocked);
  });

  it.each([
    ['lookup', (h: ReturnType<typeof harness>) => h.repo.faults.set('adminByEmail', boom)],
    ['save', (h: ReturnType<typeof harness>) => h.repo.faults.set('saveAdmin', boom)],
    ['challenge', (h: ReturnType<typeof harness>) => h.challenges.faults.set('save', boom)],
  ])('fails the password step when %s fails', async (_name, set) => {
    const h = harness();
    const { temporaryPassword } = await h.newAdmin();
    set(h);
    expect(await outcome(h.adminSignIn.login(EMAIL, temporaryPassword))).toBe(boom);
  });

  it('fails the password step on a malformed hash or an admin without email', async () => {
    const h = harness();
    const { admin, temporaryPassword } = await h.newAdmin();
    h.repo.admins.set(admin.id, { ...admin, passwordHash: 'x' });
    expect(await outcome(h.adminSignIn.login(EMAIL, temporaryPassword))).toBeInstanceOf(
      HashMalformedError,
    );
    h.repo.admins.set(admin.id, { ...admin, email: '' });
    await expect(h.adminSignIn.login('', temporaryPassword)).rejects.toThrow('account name');
  });

  it('drops a challenge after too many wrong codes', async () => {
    const h = harness();
    const { temporaryPassword } = await h.newAdmin();
    expect(await outcome(h.adminTotp.verify('missing', '123456'))).toBe(
      IdentityReasons.ChallengeExpired,
    );
    const ch = await h.adminSignIn.login(EMAIL, temporaryPassword);
    for (let i = 1; i < CHALLENGE_ATTEMPTS; i++) {
      expect(await outcome(h.adminTotp.verify(ch.id, '000000'))).toBe(IdentityReasons.TotpInvalid);
    }
    expect(await outcome(h.adminTotp.verify(ch.id, '000000'))).toBe(
      IdentityReasons.ChallengeExpired,
    );
  });

  it.each([
    ['admin', 'repo', 'adminById'],
    ['delete', 'challenges', 'delete'],
    ['save', 'repo', 'saveAdmin'],
  ] as const)('fails the TOTP step when %s fails', async (_name, fake, method) => {
    const h = harness();
    const { temporaryPassword } = await h.newAdmin();
    const ch = await h.adminSignIn.login(EMAIL, temporaryPassword);
    h[fake].faults.set(method, boom);
    expect(await outcome(h.adminTotp.verify(ch.id, await h.totp(ch.enrolSecret)))).toBe(boom);
  });

  it('refuses wrong current passwords, weak passwords and broken hashes', async () => {
    const h = harness();
    const { admin, temporaryPassword } = await h.newAdmin();
    const change = (current: string, next: string) =>
      outcome(h.adminSignIn.changePassword(admin.id, current, next));
    expect(await change('wrong', NEW_PASSWORD)).toBe(IdentityReasons.InvalidCredentials);
    expect(await change(temporaryPassword, 'short')).toBe(IdentityReasons.PasswordTooWeak);
    h.repo.faults.set('adminById', boom);
    expect(await change(temporaryPassword, 'x')).toBe(boom);
    h.repo.faults.clear();
    h.repo.admins.set(admin.id, { ...admin, passwordHash: 'x' });
    expect(await change(temporaryPassword, 'x')).toBeInstanceOf(HashMalformedError);
  });
});

describe('admin users', () => {
  it('creates, updates and lists admins', async () => {
    const h = harness();
    const { admin } = await h.newAdmin();
    const create = (email: string, roles: string[]) =>
      outcome(h.adminUsers.create({ email, name: 'X', roles }));
    expect(await create(EMAIL, ['verifier'])).toBe(IdentityReasons.EmailTaken);
    expect(await create('x@pao.bd', ['customer'])).toBe(IdentityReasons.RoleInvalid);
    const updated = await h.adminUsers.update({
      adminId: admin.id,
      roles: ['support_agent'],
      active: false,
    });
    expect(updated).toMatchObject({ active: false, roles: ['support_agent'] });
    expect(await outcome(h.adminUsers.update({ adminId: admin.id, roles: ['customer'] }))).toBe(
      IdentityReasons.RoleInvalid,
    );
    const kept = await h.adminUsers.update({ adminId: admin.id });
    expect(kept).toMatchObject({ active: false, roles: ['support_agent'] });
    expect(await h.adminUsers.list()).toHaveLength(1);
  });

  it.each(['adminByEmail', 'createAccount', 'setRoles', 'createAdminCredentials'])(
    'fails to create when %s fails',
    async (step) => {
      const h = harness();
      h.repo.faults.set(step, boom);
      const r = h.adminUsers.create({ email: 'a@pao.bd', name: 'A', roles: ['verifier'] });
      expect(await outcome(r)).toBe(boom);
    },
  );

  it.each([
    ['repo', 'adminById'],
    ['repo', 'setRoles'],
    ['families', 'listForAccount'],
  ] as const)('fails to update when %s.%s fails', async (fake, method) => {
    const h = harness();
    const { admin } = await h.newAdmin();
    h[fake].faults.set(method, boom);
    const r = h.adminUsers.update({ adminId: admin.id, roles: ['verifier'] });
    expect(await outcome(r)).toBe(boom);
  });

  it('ensures a seeded admin once, with a known password', async () => {
    const h = harness();
    const input = { email: 'super@pao.bd', name: 'Super', roles: ['super_admin'] };
    await h.adminUsers.ensure(input, 'demo password 123');
    await h.adminUsers.ensure(input, 'other password 123');
    expect(h.repo.admins.size).toBe(1);
    await expect(h.adminSignIn.login('super@pao.bd', 'demo password 123')).resolves.toBeDefined();
    const bad = { email: 'x@pao.bd', name: '', roles: ['customer'] };
    expect(await outcome(h.adminUsers.ensure(bad, 'p'))).toBe(IdentityReasons.RoleInvalid);
    h.repo.faults.set('adminByEmail', boom);
    expect(await outcome(h.adminUsers.ensure(input, 'p'))).toBe(boom);
  });
});
