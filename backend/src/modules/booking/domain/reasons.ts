/**
 * Why a booking rule refused something. Use cases throw them as `DomainError` reasons;
 * `NotFound` equals `BookingErrors.NotFound` of the contract.
 */
export const BookingReasons = {
  NotFound: 'booking.not_found',
  Invalid: 'booking.invalid',
  InvalidTransition: 'booking.invalid_transition',
  DeadlinePassed: 'booking.deadline_passed',
  ActiveJob: 'booking.active_job',
  CodeWrong: 'booking.code_wrong',
  CodeLocked: 'booking.code_locked',
  CashNotConfirmed: 'booking.cash_not_confirmed',
  ExtrasPending: 'booking.extras_pending',
  NoProposal: 'booking.no_proposal',
  NotBookable: 'booking.not_bookable',
  DuplicateRequest: 'booking.duplicate_request',
  CancelNotAllowed: 'booking.cancel_not_allowed',
  OutsideArea: 'booking.outside_area',
  ProfileRequired: 'booking.profile_required',
} as const;

/** A reason from {@link BookingReasons}. */
export type BookingReason = (typeof BookingReasons)[keyof typeof BookingReasons];
