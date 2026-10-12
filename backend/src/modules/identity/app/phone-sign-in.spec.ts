import { isDomainError } from '../../../platform/errors/domain-error';
import { boom } from '../../../../test/fakes/identity';
import { E164, harness, PHONE } from '../../../../test/fakes/identity-harness';
import { IdentityEvents } from '../contract';
import { CODE_MAX_ATTEMPTS } from '../domain/code';
import { IdentityReasons } from '../domain/reasons';
import { CodeRateLimitedError } from './phone-codes';

const rejectsWith = async (p: Promise<unknown>, reason: string) => {
  const err = await p.then(
    () => undefined,
    (e: unknown) => e,
  );
  expect(isDomainError(err, reason)).toBe(true);
};

describe('phone sign-in', () => {
  it('creates the account, then adds the partner role once', async () => {
    const h = harness();
    const first = await h.login('customer');
    expect(first).toMatchObject({ isNewAccount: true, account: { roles: ['customer'] } });
    expect(first.refreshToken).not.toBe('');
    expect(h.repo.events[0]?.name).toBe(IdentityEvents.AccountCreated);
    h.nextWindow();
    const second = await h.login('partner');
    expect(second.isNewAccount).toBe(false);
    expect(second.account).toMatchObject({ id: first.account.id, roles: ['customer', 'provider'] });
    expect(h.repo.events[1]?.name).toBe(IdentityEvents.RoleGranted);
    h.nextWindow();
    const third = await h.login('partner');
    expect(third.isNewAccount).toBe(false);
    expect(h.repo.events).toHaveLength(2);
  });

  it('locks a code out after five wrong guesses', async () => {
    const h = harness();
    await rejectsWith(
      h.signIn.verify({ phone: 'x', code: '', app: '' }),
      IdentityReasons.InvalidPhone,
    );
    await rejectsWith(
      h.signIn.verify({ phone: PHONE, code: '000000', app: 'customer' }),
      IdentityReasons.CodeExpired,
    );
    await h.phoneCodes.send({ phone: PHONE, purpose: 'login' });
    const wrong = h.sentCode() === '999999' ? '999998' : '999999';
    const guess = () => h.signIn.verify({ phone: PHONE, code: wrong, app: 'customer' });
    for (let i = 1; i < CODE_MAX_ATTEMPTS; i++) {
      await rejectsWith(guess(), IdentityReasons.CodeInvalid);
    }
    await rejectsWith(guess(), IdentityReasons.CodeLocked);
    expect(h.codes.codes.size).toBe(0);
  });

  it.each([
    ['get', (h: ReturnType<typeof harness>) => h.codes.faults.set('get', boom)],
    ['increment', (h: ReturnType<typeof harness>) => h.codes.faults.set('incrementAttempts', boom)],
    [
      'malformed hash',
      (h: ReturnType<typeof harness>) =>
        h.codes.codes.set(`login:${E164}`, { hash: 'bad', attempts: 0 }),
    ],
  ])('fails when the code store fails: %s', async (_name, set) => {
    const h = harness();
    await h.phoneCodes.send({ phone: PHONE, purpose: 'login' });
    set(h);
    await expect(
      h.signIn.verify({ phone: PHONE, code: '000000x', app: 'customer' }),
    ).rejects.toThrow();
  });

  it.each([
    ['lookup', 'repo', 'accountByPhone'],
    ['create', 'repo', 'createAccount'],
    ['grant', 'repo', 'grantRole'],
    ['publish', 'repo', 'publish'],
    ['version', 'rbac', 'version'],
    ['sign', 'signer', 'sign'],
    ['session', 'families', 'save'],
    ['delete code', 'codes', 'delete'],
  ] as const)('reports a failing %s', async (_name, fake, method) => {
    const h = harness();
    await h.phoneCodes.send({ phone: PHONE, purpose: 'login' });
    h[fake].faults.set(method, boom);
    await expect(
      h.signIn.verify({ phone: PHONE, code: h.sentCode(), app: 'customer' }),
    ).rejects.toBe(boom);
  });

  it.each(['grantRole', 'publish'])('reports a failing %s for a returning person', async (m) => {
    const h = harness();
    await h.login('customer');
    h.nextWindow();
    await h.phoneCodes.send({ phone: PHONE, purpose: 'login' });
    h.repo.faults.set(m, boom);
    await expect(
      h.signIn.verify({ phone: PHONE, code: h.sentCode(), app: 'partner' }),
    ).rejects.toBe(boom);
  });

  it('refuses a banned account', async () => {
    const h = harness();
    const s = await h.login('customer');
    h.repo.accounts.set(s.account.id, { ...s.account, status: 'banned' });
    h.nextWindow();
    await h.phoneCodes.send({ phone: PHONE, purpose: 'login' });
    await rejectsWith(
      h.signIn.verify({ phone: PHONE, code: h.sentCode(), app: 'partner' }),
      IdentityReasons.AccountBanned,
    );
  });
});

describe('sending codes', () => {
  it('refuses bad and blocked phones but sends other codes to blocked ones', async () => {
    const h = harness();
    await rejectsWith(
      h.phoneCodes.send({ phone: '123', purpose: 'login' }),
      IdentityReasons.InvalidPhone,
    );
    h.repo.blocked.add(E164);
    await rejectsWith(
      h.phoneCodes.send({ phone: PHONE, purpose: 'login' }),
      IdentityReasons.AccountBanned,
    );
    await expect(h.phoneCodes.send({ phone: PHONE, purpose: 'delete_account' })).resolves.toBe(
      E164,
    );
    h.repo.faults.set('isPhoneBlocked', boom);
    await expect(h.phoneCodes.send({ phone: PHONE, purpose: 'login' })).rejects.toBe(boom);
  });

  it('reports how long to wait when a window is exhausted', async () => {
    const h = harness();
    h.throttle.blocked = 'ip:9.9.9.9';
    const err: unknown = await h.phoneCodes
      .send({ phone: PHONE, purpose: 'login', clientIp: '9.9.9.9' })
      .catch((e: unknown) => e);
    expect(err).toBeInstanceOf(CodeRateLimitedError);
    expect((err as CodeRateLimitedError).retryAfterMs).toBe(42_000);
    expect(isDomainError(err, IdentityReasons.RateLimited)).toBe(true);
  });

  it.each([
    ['throttle', 'throttle', 'retryAfterMs'],
    ['store', 'codes', 'save'],
    ['sms', 'sms', 'send'],
  ] as const)('reports a failing %s', async (_name, fake, method) => {
    const h = harness();
    h[fake].faults.set(method, boom);
    await expect(h.phoneCodes.send({ phone: PHONE, purpose: 'login' })).rejects.toThrow();
  });

  it('checks codes typed for other purposes', async () => {
    const h = harness();
    await rejectsWith(
      h.phoneCodes.checkTyped('bad', 'emergency_contact', '1'),
      IdentityReasons.InvalidPhone,
    );
    await h.phoneCodes.send({ phone: PHONE, purpose: 'emergency_contact' });
    await expect(
      h.phoneCodes.checkTyped(PHONE, 'emergency_contact', h.sentCode()),
    ).resolves.toBeUndefined();
  });
});
