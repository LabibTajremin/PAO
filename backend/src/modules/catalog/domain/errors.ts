/**
 * Reasons of the `DomainError`s the catalog use cases raise. The domain stays free of
 * platform imports, so it only names them; the use cases throw.
 */
export const CatalogReason = {
  /** No category, service or sub-service has the id. */
  NotFound: 'catalog.not_found',
  /** The item breaks a catalog rule (names, icon, model, level, radius, unit). */
  Invalid: 'catalog.invalid',
  /** A price below zero. */
  PriceNegative: 'catalog.price_negative',
} as const;
