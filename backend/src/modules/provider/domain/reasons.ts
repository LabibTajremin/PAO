/**
 * Why a provider rule refused something. Use cases throw them as `DomainError` reasons;
 * the values shared with the contract equal `ProviderErrors`.
 */
export const ProviderReasons = {
  NotFound: 'provider.not_found',
  EnrolmentIncomplete: 'provider.enrolment_incomplete',
  Invalid: 'provider.invalid',
  TooYoung: 'provider.too_young',
  UnknownService: 'provider.unknown_service',
  NotVerified: 'provider.not_verified',
  NoServiceArea: 'provider.no_service_area',
  Offline: 'provider.offline',
  ContactUnproven: 'provider.contact_unproven',
  CodeRejected: 'provider.code_rejected',
  CodeRateLimited: 'provider.code_rate_limited',
  InvalidPhoto: 'provider.invalid_photo',
} as const;

/** A reason from {@link ProviderReasons}. */
export type ProviderReason = (typeof ProviderReasons)[keyof typeof ProviderReasons];
