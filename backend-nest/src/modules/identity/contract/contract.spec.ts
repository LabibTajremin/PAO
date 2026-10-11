import {
  AccountStatus,
  CodePurpose,
  IDENTITY_SERVICE,
  IdentityErrors,
  IdentityEvents,
  Role,
} from './index';

describe('identity contract', () => {
  it('keeps the stored event names of the Go backend', () => {
    expect(IdentityEvents).toEqual({
      AccountCreated: 'identity.AccountCreated',
      RoleGranted: 'identity.RoleGranted',
      AccountStatusChanged: 'identity.AccountStatusChanged',
      AccountDeleted: 'identity.AccountDeleted',
    });
  });

  it('scopes every error reason to identity', () => {
    const reasons = Object.values(IdentityErrors);
    expect(reasons.every((r) => r.startsWith('identity.'))).toBe(true);
    expect(new Set(reasons).size).toBe(reasons.length);
  });

  it('matches the role, status and purpose values stored in the database', () => {
    expect(Object.values(Role)).toEqual([
      'customer',
      'provider',
      'verifier',
      'catalog_manager',
      'support_agent',
      'super_admin',
    ]);
    expect(Object.values(AccountStatus)).toEqual(['pending', 'active', 'suspended', 'banned']);
    expect(Object.values(CodePurpose)).toEqual(['login', 'delete_account', 'emergency_contact']);
  });

  it('names its injection token after the service', () => {
    expect(IDENTITY_SERVICE.description).toBe('IdentityService');
  });
});
