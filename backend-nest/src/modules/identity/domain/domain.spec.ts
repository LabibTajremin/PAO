import { IdentityErrors } from '../contract';
import {
  type Account,
  canChangeStatus,
  isAdminRoleSet,
  roleForApp,
  signInRefusal,
} from './account';
import {
  ADMIN_LOCKOUT_MS,
  ADMIN_MAX_FAILURES,
  type Admin,
  adminLoginRefusal,
  isStrongPassword,
  recordFailure,
  recordSuccess,
} from './admin';
import { checkAttempt } from './code';
import { maskPhone, normalizePhone } from './phone';
import { IdentityReasons } from './reasons';
import {
  familyMatches,
  type Family,
  formatRefreshToken,
  parseRefreshToken,
  PROVIDER_GATE_SCREENS,
} from './session';

const account = (over: Partial<Account> = {}): Account => ({
  id: 'a',
  phone: '',
  email: '',
  name: '',
  status: 'active',
  roles: [],
  createdAt: new Date(),
  deletedAt: null,
  ...over,
});

describe('phone numbers', () => {
  it.each([
    ['01712345678', '+8801712345678'],
    ['8801712345678', '+8801712345678'],
    ['+8801712345678', '+8801712345678'],
    [' +880 1712-345678', '+8801712345678'],
    ['(017) 1234 5678', '+8801712345678'],
    ['1912345678', '+8801912345678'],
  ])('normalizes %s', (raw, want) => {
    expect(normalizePhone(raw)).toBe(want);
  });

  it.each(['', '0171234567', '01212345678', '+9101712345678', '017123456789', 'phone'])(
    'refuses %s',
    (raw) => {
      expect(normalizePhone(raw)).toBeUndefined();
    },
  );

  it('masks all but the last three digits', () => {
    expect(maskPhone('+8801712345678')).toBe('***********678');
    expect(maskPhone('1')).toBe('***');
  });
});

describe('accounts', () => {
  it('refuses sign-in for deleted, banned and suspended accounts', () => {
    expect(signInRefusal(account())).toBeUndefined();
    expect(signInRefusal(account({ status: 'pending' }))).toBeUndefined();
    expect(signInRefusal(account({ status: 'suspended' }))).toBe(IdentityReasons.AccountSuspended);
    expect(signInRefusal(account({ status: 'banned' }))).toBe(IdentityReasons.AccountBanned);
    expect(signInRefusal(account({ deletedAt: new Date() }))).toBe(IdentityReasons.AccountDeleted);
  });

  it('allows suspend, ban and reinstate but no no-op or deleted account', () => {
    expect(canChangeStatus(account(), 'suspended')).toBe(true);
    expect(canChangeStatus(account(), 'banned')).toBe(true);
    expect(canChangeStatus(account({ status: 'banned' }), 'active')).toBe(true);
    expect(canChangeStatus(account(), 'active')).toBe(false);
    expect(canChangeStatus(account(), 'pending')).toBe(false);
    expect(canChangeStatus(account({ deletedAt: new Date() }), 'banned')).toBe(false);
  });

  it('maps apps to roles and recognises admin role sets', () => {
    expect(roleForApp('partner')).toBe('provider');
    expect(roleForApp('customer')).toBe('customer');
    expect(isAdminRoleSet(['verifier', 'super_admin'])).toBe(true);
    expect(isAdminRoleSet([])).toBe(false);
    expect(isAdminRoleSet(['customer'])).toBe(false);
  });

  it('shares the contract reasons other modules compare against', () => {
    expect(IdentityReasons.AccountNotFound).toBe(IdentityErrors.AccountNotFound);
    expect(IdentityReasons.CodeInvalid).toBe(IdentityErrors.CodeInvalid);
    expect(IdentityReasons.CodeExpired).toBe(IdentityErrors.CodeExpired);
    expect(IdentityReasons.CodeLocked).toBe(IdentityErrors.CodeLocked);
    expect(IdentityReasons.RateLimited).toBe(IdentityErrors.RateLimited);
    expect(IdentityReasons.StatusChange).toBe(IdentityErrors.StatusInvalid);
  });
});

describe('one-time codes', () => {
  it('accepts a match, then locks out on the fifth wrong guess', () => {
    expect(checkAttempt({ hash: '', attempts: 0 }, true)).toEqual({ discard: true });
    expect(checkAttempt({ hash: '', attempts: 3 }, false)).toEqual({
      discard: false,
      refusal: IdentityReasons.CodeInvalid,
    });
    expect(checkAttempt({ hash: '', attempts: 4 }, false)).toEqual({
      discard: true,
      refusal: IdentityReasons.CodeLocked,
    });
  });
});

describe('refresh tokens', () => {
  it('round-trips and refuses malformed tokens', () => {
    const id = '0199c4f0-0000-7000-8000-000000000001';
    expect(parseRefreshToken(formatRefreshToken(id, 'secret'))).toEqual({
      familyId: id,
      secret: 'secret',
    });
    for (const bad of ['', 'nodot', 'not-a-uuid.secret', `${id}.`]) {
      expect(parseRefreshToken(bad)).toBeUndefined();
    }
    const f = { currentHash: 'abc' } as Family;
    expect(familyMatches(f, 'abc')).toBe(true);
    expect(familyMatches(f, 'abd')).toBe(false);
    expect(familyMatches(f, 'abcd')).toBe(false);
    expect(PROVIDER_GATE_SCREENS).toHaveLength(14);
    expect(PROVIDER_GATE_SCREENS.at(-1)).toBe('M14');
  });
});

describe('admins', () => {
  const now = new Date('2026-10-09T10:00:00Z');

  it('locks out after the limit, for the lockout period', () => {
    let a = { ...account(), active: true, failedAttempts: 0, lockedUntil: null } as Admin;
    for (let i = 0; i < ADMIN_MAX_FAILURES - 1; i++) {
      a = recordFailure(a, now);
    }
    expect(adminLoginRefusal(a, now)).toBeUndefined();
    a = recordFailure(a, now);
    expect(adminLoginRefusal(a, now)).toBe(IdentityReasons.AdminLocked);
    expect(a.failedAttempts).toBe(0);
    expect(adminLoginRefusal(a, new Date(now.getTime() + ADMIN_LOCKOUT_MS))).toBeUndefined();
    expect(recordSuccess(a).lockedUntil).toBeNull();
    expect(adminLoginRefusal({ ...a, active: false }, now)).toBe(IdentityReasons.AdminInactive);
  });

  it.each([
    ['short1', false],
    ['onlyletterslongenough', false],
    ['123456789012345', false],
    ['correct horse battery 2026', true],
  ])('judges password %s', (pw, strong) => {
    expect(isStrongPassword(pw)).toBe(strong);
  });
});
