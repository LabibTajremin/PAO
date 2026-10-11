/**
 * `DomainError` reasons verification raises through its contract; other modules
 * compare against these with `isDomainError`.
 */
export const VerificationErrors = {
  /** Verification has no record of the provider. */
  ProviderNotFound: 'verification.provider_not_found',
} as const;

/** A reason from {@link VerificationErrors}. */
export type VerificationErrorReason = (typeof VerificationErrors)[keyof typeof VerificationErrors];
