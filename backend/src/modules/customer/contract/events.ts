import { type DomainEvent } from '../../../platform/events/domain-event';

/** Outbox names of the customer module's events; stored, so they never change. */
export const CustomerEvents = {
  CustomerProfileSaved: 'customer.CustomerProfileSaved',
} as const;

/**
 * Published when a customer creates or renames their profile, so read models (admin
 * search, booking snapshots) can refresh the display name.
 */
export interface CustomerProfileSaved extends DomainEvent<
  typeof CustomerEvents.CustomerProfileSaved
> {
  readonly customerId: string;
  /** Go's `Name`; renamed because `name` is the event name on every DomainEvent. */
  readonly customerName: string;
}

/** Any event the customer module publishes. */
export type CustomerEvent = CustomerProfileSaved;
