import { type Point } from '../geo/point';
import { type Text } from '../i18n/text';

/** A sub-service of the seed catalog, its price in paisa. */
export interface SeedSubService {
  readonly key: string;
  readonly name: Text;
  readonly unit: string;
  readonly pricePaisa: number;
  readonly maxQuantity: number;
}

/** A service of the seed catalog. */
export interface SeedService {
  readonly key: string;
  readonly name: Text;
  readonly icon: string;
  readonly model: string;
  readonly requiredLevel: number;
  readonly searchRadiusM: number;
  readonly womenProvidersOnly: boolean;
  readonly requiresLevel2: boolean;
  readonly level2Checklist: readonly Text[];
  readonly subServices: readonly SeedSubService[];
}

/** A category of the seed catalog (`seed/catalog.yaml`). */
export interface SeedCategory {
  readonly key: string;
  readonly name: Text;
  readonly icon: string;
  readonly services: readonly SeedService[];
}

/** A demo admin of the seed file. */
export interface SeedAdmin {
  readonly email: string;
  readonly name: string;
  readonly roles: readonly string[];
}

/** Loads the seed catalog idempotently; the catalog module provides it. */
export interface CatalogSeeder {
  seedCatalog(categories: readonly SeedCategory[]): Promise<void>;
}

/** Injection token for the {@link CatalogSeeder}. */
export const CATALOG_SEEDER = Symbol('CatalogSeeder');

/** Creates a demo admin unless it exists; the identity module provides it. */
export interface AdminSeeder {
  ensureAdmin(admin: SeedAdmin, password: string): Promise<void>;
}

/** Injection token for the {@link AdminSeeder}. */
export const ADMIN_SEEDER = Symbol('AdminSeeder');

/**
 * Puts verified providers online for the load test without going through enrolment;
 * the provider module provides it (writing provider and verification rows directly,
 * as the Go perf seed did).
 */
export interface PerfSeeder {
  /** The seeded electrician service and its fan-install sub-service. */
  readonly serviceId: string;
  readonly subServiceId: string;
  addOnlineProvider(providerId: string, at: Point): Promise<void>;
}

/** Injection token for the {@link PerfSeeder}. */
export const PERF_SEEDER = Symbol('PerfSeeder');
