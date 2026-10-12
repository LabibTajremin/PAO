import { type Text } from '../../../platform/i18n/text';

/** Booking states from docs/booking-states.md. */
export const BookingStatus = {
  Requested: 'requested',
  Accepted: 'accepted',
  OnTheWay: 'on_the_way',
  Arrived: 'arrived',
  InProgress: 'in_progress',
  Completed: 'completed',
  Rejected: 'rejected',
  TimedOut: 'timed_out',
  Cancelled: 'cancelled',
} as const;

/** A booking state from docs/booking-states.md. */
export type BookingStatus = (typeof BookingStatus)[keyof typeof BookingStatus];

/** The cross-module view of a booking. */
export interface Booking {
  readonly id: string;
  readonly number: string;
  readonly status: BookingStatus;
  readonly customerId: string;
  readonly providerId: string;
  readonly serviceId: string;
  readonly serviceName: Text;
  readonly customerName: string;
  readonly providerName: string;
  readonly area: string;
  readonly totalPaisa: number;
  readonly createdAt: Date;
  readonly completedAt: Date | null;
}

/** A compact list entry. */
export interface BookingSummary {
  readonly id: string;
  readonly number: string;
  readonly status: BookingStatus;
  readonly serviceName: Text;
  readonly totalPaisa: number;
  readonly createdAt: Date;
}

/** Counters derived from a provider's bookings. */
export interface ProviderStats {
  readonly completedJobs: number;
  readonly cancellations30d: number;
}
