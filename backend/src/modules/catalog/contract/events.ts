import { type DomainEvent } from '../../../platform/events/domain-event';

/** Outbox names of the catalog's events; stored, so they never change. */
export const CatalogEvents = {
  CatalogChanged: 'catalog.CatalogChanged',
  PriceChanged: 'catalog.PriceChanged',
} as const;

/** Published after any catalog edit so caches keyed by version expire. */
export interface CatalogChanged extends DomainEvent<typeof CatalogEvents.CatalogChanged> {
  readonly version: number;
}

/** Published when a sub-service gets a new price version. */
export interface PriceChanged extends DomainEvent<typeof CatalogEvents.PriceChanged> {
  readonly subServiceId: string;
  readonly priceVersionId: string;
  readonly amountPaisa: number;
  /** Null for system actions (Go used the nil UUID). */
  readonly actorId: string | null;
}

/** Any event the catalog publishes. */
export type CatalogEvent = CatalogChanged | PriceChanged;
