import { type DomainEvent } from '../../../platform/events/domain-event';
import { type Text } from '../../../platform/i18n/text';

/** Outbox names of the booking module's events; stored, so they never change. */
export const BookingEvents = {
  BookingRequested: 'booking.BookingRequested',
  BookingAccepted: 'booking.BookingAccepted',
  BookingRejected: 'booking.BookingRejected',
  BookingTimedOut: 'booking.BookingTimedOut',
  ProviderOnTheWay: 'booking.ProviderOnTheWay',
  ProviderArrived: 'booking.ProviderArrived',
  BookingStarted: 'booking.BookingStarted',
  ExtraItemsProposed: 'booking.ExtraItemsProposed',
  ExtraItemsDecided: 'booking.ExtraItemsDecided',
  BookingCompleted: 'booking.BookingCompleted',
  BookingCancelled: 'booking.BookingCancelled',
} as const;

/**
 * Who a booking event concerns; every booking event carries it so notification and
 * read models can route without calling back.
 */
export interface BookingParties {
  readonly bookingId: string;
  readonly number: string;
  readonly customerId: string;
  readonly providerId: string;
  readonly serviceId: string;
  /** ISO-8601 time the change happened. */
  readonly at: string;
}

/** Published when a customer requests a provider. */
export interface BookingRequested
  extends DomainEvent<typeof BookingEvents.BookingRequested>, BookingParties {
  /** ISO-8601 time by which the provider must respond. */
  readonly acceptDeadline: string;
  readonly scheduled: boolean;
  readonly totalPaisa: number;
}

/** Published when the provider accepts. */
export interface BookingAccepted
  extends DomainEvent<typeof BookingEvents.BookingAccepted>, BookingParties {}

/** Published when the provider rejects. */
export interface BookingRejected
  extends DomainEvent<typeof BookingEvents.BookingRejected>, BookingParties {
  readonly reason: string;
}

/** Published when the accept time limit passes. */
export interface BookingTimedOut
  extends DomainEvent<typeof BookingEvents.BookingTimedOut>, BookingParties {}

/** Published when the provider sets off. */
export interface ProviderOnTheWay
  extends DomainEvent<typeof BookingEvents.ProviderOnTheWay>, BookingParties {}

/** Published when the provider arrives. */
export interface ProviderArrived
  extends DomainEvent<typeof BookingEvents.ProviderArrived>, BookingParties {}

/** Published after the correct start code is entered. */
export interface BookingStarted
  extends DomainEvent<typeof BookingEvents.BookingStarted>, BookingParties {}

/** Published when the provider proposes extra catalog items. */
export interface ExtraItemsProposed
  extends DomainEvent<typeof BookingEvents.ExtraItemsProposed>, BookingParties {
  readonly proposalId: string;
  readonly addedPaisa: number;
  readonly newTotalPaisa: number;
}

/** Published when the customer approves or declines extras. */
export interface ExtraItemsDecided
  extends DomainEvent<typeof BookingEvents.ExtraItemsDecided>, BookingParties {
  readonly proposalId: string;
  readonly approved: boolean;
}

/** Published when the job is complete and cash is confirmed. */
export interface BookingCompleted
  extends DomainEvent<typeof BookingEvents.BookingCompleted>, BookingParties {
  readonly totalPaisa: number;
  readonly customerName: string;
  readonly providerName: string;
  readonly serviceName: Text;
}

/** Published when either side cancels. */
export interface BookingCancelled
  extends DomainEvent<typeof BookingEvents.BookingCancelled>, BookingParties {
  /** The side that cancelled. */
  readonly by: string;
  readonly reason: string;
  /**
   * True when the provider had already accepted; provider cancellations after
   * acceptance count against quality (PRD §6.4).
   */
  readonly afterAcceptance: boolean;
}

/** Any event the booking module publishes. */
export type BookingEvent =
  | BookingRequested
  | BookingAccepted
  | BookingRejected
  | BookingTimedOut
  | ProviderOnTheWay
  | ProviderArrived
  | BookingStarted
  | ExtraItemsProposed
  | ExtraItemsDecided
  | BookingCompleted
  | BookingCancelled;
