/**
 * `DomainError` reasons the catalog raises through its contract; other modules compare
 * against these with `isDomainError`.
 */
export const CatalogErrors = {
  /** No service has the id. */
  ServiceNotFound: 'catalog.service_not_found',
  /** No sub-service has the id. */
  SubServiceNotFound: 'catalog.sub_service_not_found',
} as const;

/** A reason from {@link CatalogErrors}. */
export type CatalogErrorReason = (typeof CatalogErrors)[keyof typeof CatalogErrors];
