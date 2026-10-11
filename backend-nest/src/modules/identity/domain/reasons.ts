/**
 * Why an identity rule refused something. Use cases throw them as `DomainError`
 * reasons; the values shared with the contract equal `IdentityErrors`.
 */
export const IdentityReasons = {
  InvalidPhone: 'identity.invalid_phone',
  AccountNotFound: 'identity.account_not_found',
  AccountBanned: 'identity.account_banned',
  AccountSuspended: 'identity.account_suspended',
  AccountDeleted: 'identity.account_deleted',
  StatusChange: 'identity.status_invalid',
  CodeInvalid: 'identity.code_invalid',
  CodeExpired: 'identity.code_expired',
  CodeLocked: 'identity.code_locked',
  RateLimited: 'identity.rate_limited',
  RefreshInvalid: 'identity.refresh_invalid',
  RefreshReused: 'identity.refresh_reused',
  InvalidCredentials: 'identity.invalid_credentials',
  AdminLocked: 'identity.admin_locked',
  AdminInactive: 'identity.admin_inactive',
  ChallengeExpired: 'identity.challenge_expired',
  TotpInvalid: 'identity.totp_invalid',
  EmailTaken: 'identity.email_taken',
  RoleInvalid: 'identity.role_invalid',
  PasswordTooWeak: 'identity.password_too_weak',
} as const;

/** A reason from {@link IdentityReasons}. */
export type IdentityReason = (typeof IdentityReasons)[keyof typeof IdentityReasons];
