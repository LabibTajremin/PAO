/**
 * `DomainError` reasons identity raises through its contract; other modules compare
 * against these with `isDomainError`.
 */
export const IdentityErrors = {
  /** No account has the id. */
  AccountNotFound: 'identity.account_not_found',
  /** The one-time code is wrong. */
  CodeInvalid: 'identity.code_invalid',
  /** The one-time code expired or was never sent. */
  CodeExpired: 'identity.code_expired',
  /** Too many wrong codes were entered. */
  CodeLocked: 'identity.code_locked',
  /** Too many codes were requested. */
  RateLimited: 'identity.rate_limited',
  /** The requested status change is not allowed from the current status. */
  StatusInvalid: 'identity.status_invalid',
} as const;

/** A reason from {@link IdentityErrors}. */
export type IdentityErrorReason = (typeof IdentityErrors)[keyof typeof IdentityErrors];
