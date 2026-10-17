/**
 * `DomainError` reasons the booking module raises through its contract; other modules
 * compare against these with `isDomainError`.
 */
export const BookingErrors = {
  /** No booking has the id. */
  NotFound: 'booking.not_found',
} as const;

/** A reason from {@link BookingErrors}. */
export type BookingErrorReason = (typeof BookingErrors)[keyof typeof BookingErrors];
