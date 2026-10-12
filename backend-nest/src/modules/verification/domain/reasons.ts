/**
 * Why a verification rule refused something. Use cases throw them as `DomainError`
 * reasons; the value shared with the contract equals `VerificationErrors`.
 */
export const VerificationReasons = {
  NotFound: 'verification.provider_not_found',
  Invalid: 'verification.invalid',
  NotPending: 'verification.not_pending',
  ClearanceTooOld: 'verification.clearance_too_old',
  NidBlocked: 'verification.nid_blocked',
  BadDocument: 'verification.bad_document',
  NotEligible: 'verification.not_eligible',
  CoolingOff: 'verification.cooling_off',
  SessionClosed: 'verification.session_closed',
  EnrolmentPending: 'verification.enrolment_pending',
} as const;

/** A reason from {@link VerificationReasons}. */
export type VerificationReason = (typeof VerificationReasons)[keyof typeof VerificationReasons];
