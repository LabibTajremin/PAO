import { type CatalogEvent } from '../contract/events';
import {
  type Category,
  type CategoryFields,
  type PriceVersion,
  type Service,
  type ServiceFields,
  type SubService,
  type SubServiceFields,
} from '../domain/catalog';

/** Ids of published services and sub-services matching a search, best match first. */
export interface SearchHits {
  readonly serviceIds: readonly string[];
  readonly subServiceIds: readonly string[];
}

/** Writes catalog rows inside one transaction. */
export interface CatalogWriter {
  saveCategory(c: CategoryFields): Promise<void>;
  saveService(s: ServiceFields): Promise<void>;
  saveSubService(s: SubServiceFields): Promise<void>;
  /** Inserts an immutable price version and makes it current. */
  addPrice(p: PriceVersion): Promise<void>;
  /** Bumps the catalog version, expiring cached trees; returns the new version. */
  bumpVersion(): Promise<number>;
  /** Stores an event in the catalog outbox, committed with the change. */
  publish(aggregateId: string, event: CatalogEvent): Promise<void>;
}

/** Reads the catalog and opens transactions. */
export interface CatalogRepository {
  /** Every category with its services and sub-services, published or not. */
  tree(): Promise<Category[]>;
  categoryExists(id: string): Promise<boolean>;
  /** The service with all its sub-services; throws `catalog.not_found`. */
  service(id: string): Promise<Service>;
  /** The sub-service with its current price; throws `catalog.not_found`. */
  subService(id: string): Promise<SubService>;
  /** Price versions, newest first. */
  priceHistory(subServiceId: string): Promise<PriceVersion[]>;
  search(term: string): Promise<SearchHits>;
  version(): Promise<number>;
  transaction<T>(fn: (w: CatalogWriter) => Promise<T>): Promise<T>;
}

/** Injection token for the {@link CatalogRepository}. */
export const CATALOG_REPOSITORY = Symbol('CatalogRepository');

/** Stores rendered catalog trees (`cache:catalog:v{version}`). */
export interface TreeCache {
  get<T>(key: string): Promise<T | undefined>;
  set(key: string, value: unknown, ttlMs: number): Promise<void>;
}

/** Injection token for the {@link TreeCache}. */
export const TREE_CACHE = Symbol('CatalogTreeCache');
