import { type DomainEvent } from '../../../platform/events/domain-event';
import { type Booking, type Text } from '../domain/booking';

/** Mutates a booking and returns the events to publish with it. */
export type Change = (b: Booking) => Promise<DomainEvent[]>;

/** A keyset position over (time, id); `limit` includes the look-ahead row. */
export interface Page {
  readonly at: Date | null;
  readonly id: string | null;
  readonly limit: number;
}

/** Narrows the admin bookings monitor; `from` and `until` bound created_at. */
export interface Filter {
  readonly status: string | null;
  readonly serviceId: string | null;
  readonly from: Date | null;
  readonly until: Date | null;
  readonly area: string;
}

/** A list row. */
export interface Summary {
  readonly id: string;
  readonly number: number;
  readonly status: string;
  readonly serviceName: Text;
  readonly customerName: string;
  readonly providerName: string;
  readonly scheduled: boolean;
  readonly scheduledAt: Date | null;
  readonly totalPaisa: number;
  readonly createdAt: Date;
}

/** One Dhaka calendar day of earnings. */
export interface DayTotal {
  readonly day: Date;
  readonly total: number;
  readonly jobs: number;
}

/** One completed job in the earnings list. */
export interface EarningsJob {
  readonly id: string;
  readonly number: number;
  readonly completedAt: Date;
  readonly serviceName: Text;
  readonly totalPaisa: number;
}

/** A half-open time range [from, until). */
export interface Range {
  readonly from: Date;
  readonly until: Date;
}

/**
 * Stores bookings. `change` holds the provider's advisory lock and the booking's row
 * lock, so the one-active-job rule and concurrent accepts are decided one at a time.
 */
export interface BookingRepository {
  /**
   * Inserts a booking; a repeated idempotency key returns the stored booking with
   * `created` false (PRD §9.6). `event` builds the creation event once the booking
   * number is known.
   */
  create(
    b: Booking,
    event: (b: Booking) => DomainEvent,
  ): Promise<{ booking: Booking; created: boolean }>;
  /** Returns the booking, or throws `booking.not_found`. */
  get(id: string): Promise<Booking>;
  /** Applies `fn` under the locks and saves the booking with its events. */
  change(id: string, fn: Change): Promise<Booking>;
  /** A party's bookings in `statuses`, newest first. */
  list(
    party: { id: string; asProvider: boolean },
    statuses: readonly string[],
    p: Page,
  ): Promise<Summary[]>;
  /** Every booking matching the admin filters (A-06). */
  monitor(f: Filter, p: Page): Promise<Summary[]>;
  /** Requests whose accept deadline passed. */
  due(now: Date): Promise<string[]>;
  earningsByDay(providerId: string, r: Range): Promise<DayTotal[]>;
  earningsJobs(providerId: string, r: Range, p: Page): Promise<EarningsJob[]>;
  /** Completed jobs, and provider cancellations after acceptance since `since`. */
  stats(providerId: string, since: Date): Promise<{ completed: number; cancellations: number }>;
  countActive(providerId: string): Promise<number>;
}

/** Injection token for the {@link BookingRepository}. */
export const BOOKING_REPOSITORY = Symbol('BookingRepository');
