import { type Booking, type BookingSummary, type ProviderStats } from './dto';

/** What other modules may ask of the booking module (PRD §9.3 rule 1). */
export interface BookingService {
  /**
   * Returns a booking with its parties and snapshots, or throws
   * `BookingErrors.NotFound`.
   */
  getBooking(bookingId: string): Promise<Booking>;
  /**
   * Returns how many accepted-but-unfinished jobs the provider has; the MVP allows one
   * active ASAP job at a time (PRD §5).
   */
  countActiveJobs(providerId: string): Promise<number>;
  /**
   * Returns completed jobs and recent provider cancellations, used for search cards and
   * quality thresholds (D13).
   */
  getProviderStats(providerId: string): Promise<ProviderStats>;
  /** Returns a party's latest bookings for admin detail pages. */
  listRecentBookings(partyId: string, limit: number): Promise<BookingSummary[]>;
}

/** Injection token for the {@link BookingService}. */
export const BOOKING_SERVICE = Symbol('BookingService');
