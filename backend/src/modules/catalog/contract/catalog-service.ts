import { type PriceSnapshot, type Service } from './dto';

/** What other modules may ask of the catalog (PRD §9.3 rule 1). */
export interface CatalogService {
  /**
   * Returns a service with its rules (radius, level, women-only), or throws
   * `CatalogErrors.ServiceNotFound`.
   */
  getService(serviceId: string): Promise<Service>;
  /**
   * Returns the current price version of a sub-service so a booking can copy it
   * (PRD §4: past bookings keep the price that applied), or throws
   * `CatalogErrors.SubServiceNotFound`.
   */
  getPriceSnapshot(subServiceId: string): Promise<PriceSnapshot>;
  /** Returns every published service, for enrolment and admin filters. */
  listServices(): Promise<Service[]>;
}

/** Injection token for the {@link CatalogService}. */
export const CATALOG_SERVICE = Symbol('CatalogService');
