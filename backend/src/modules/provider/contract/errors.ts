/**
 * `DomainError` reasons the provider module raises through its contract; other modules
 * compare against these with `isDomainError`.
 */
export const ProviderErrors = {
  /** No provider profile has the id. */
  NotFound: 'provider.not_found',
  /** The enrolment still has open required steps. */
  EnrolmentIncomplete: 'provider.enrolment_incomplete',
} as const;

/** A reason from {@link ProviderErrors}. */
export type ProviderErrorReason = (typeof ProviderErrors)[keyof typeof ProviderErrors];
