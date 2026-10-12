// In-memory stand-ins for the catalog ports, for use-case specs.
import { DomainError } from '../../../platform/errors/domain-error';
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
import { CatalogReason } from '../domain/errors';
import {
  type CatalogRepository,
  type CatalogWriter,
  type SearchHits,
  type TreeCache,
} from '../port/catalog-repository';

/** Names of the fake's methods that can be made to fail. */
export type FakeCatalogMethod = keyof CatalogRepository | keyof CatalogWriter;

/** A catalog repository and writer over maps; `faults` makes a method throw. */
export class FakeCatalogRepository implements CatalogRepository, CatalogWriter {
  readonly faults = new Map<FakeCatalogMethod, Error>();
  readonly categories = new Map<string, CategoryFields>();
  readonly services = new Map<string, ServiceFields>();
  readonly subs = new Map<string, SubService>();
  readonly prices: PriceVersion[] = [];
  readonly events: CatalogEvent[] = [];
  hits: SearchHits = { serviceIds: [], subServiceIds: [] };
  currentVersion = 1;
  treeReads = 0;

  private fail(method: FakeCatalogMethod): void {
    const err = this.faults.get(method);
    if (err) {
      throw err;
    }
  }

  tree(): Promise<Category[]> {
    this.treeReads++;
    this.fail('tree');
    const tree = [...this.categories.values()].map((c) => ({
      ...c,
      services: this.servicesIn(c.id),
    }));
    return Promise.resolve(tree);
  }

  private servicesIn(categoryId: string): Service[] {
    return [...this.services.values()]
      .filter((s) => s.categoryId === categoryId)
      .map((s) => this.withSubs(s));
  }

  private withSubs(s: ServiceFields): Service {
    return { ...s, subServices: [...this.subs.values()].filter((ss) => ss.serviceId === s.id) };
  }

  categoryExists(id: string): Promise<boolean> {
    this.fail('categoryExists');
    return Promise.resolve(this.categories.has(id));
  }

  service(id: string): Promise<Service> {
    const s = this.services.get(id);
    if (!s) {
      return Promise.reject(new DomainError(CatalogReason.NotFound));
    }
    this.fail('service');
    return Promise.resolve(this.withSubs(s));
  }

  subService(id: string): Promise<SubService> {
    const s = this.subs.get(id);
    if (!s || s.priceVersionId === '') {
      return Promise.reject(new DomainError(CatalogReason.NotFound));
    }
    this.fail('subService');
    return Promise.resolve(s);
  }

  priceHistory(subServiceId: string): Promise<PriceVersion[]> {
    this.fail('priceHistory');
    return Promise.resolve(this.prices.filter((p) => p.subServiceId === subServiceId).reverse());
  }

  search(): Promise<SearchHits> {
    this.fail('search');
    return Promise.resolve(this.hits);
  }

  version(): Promise<number> {
    this.fail('version');
    return Promise.resolve(this.currentVersion);
  }

  async transaction<T>(fn: (w: CatalogWriter) => Promise<T>): Promise<T> {
    this.fail('transaction');
    return fn(this);
  }

  saveCategory(c: CategoryFields): Promise<void> {
    this.categories.set(c.id, c);
    this.fail('saveCategory');
    return Promise.resolve();
  }

  saveService(s: ServiceFields): Promise<void> {
    this.services.set(s.id, s);
    this.fail('saveService');
    return Promise.resolve();
  }

  saveSubService(s: SubServiceFields): Promise<void> {
    const old = this.subs.get(s.id);
    this.subs.set(s.id, {
      ...s,
      priceVersionId: old?.priceVersionId ?? '',
      price: old?.price ?? 0,
    });
    this.fail('saveSubService');
    return Promise.resolve();
  }

  addPrice(p: PriceVersion): Promise<void> {
    this.prices.push(p);
    const sub = this.subs.get(p.subServiceId);
    if (sub) {
      this.subs.set(p.subServiceId, { ...sub, priceVersionId: p.id, price: p.amount });
    }
    this.fail('addPrice');
    return Promise.resolve();
  }

  bumpVersion(): Promise<number> {
    this.currentVersion++;
    this.fail('bumpVersion');
    return Promise.resolve(this.currentVersion);
  }

  publish(_aggregateId: string, event: CatalogEvent): Promise<void> {
    this.events.push(event);
    this.fail('publish');
    return Promise.resolve();
  }
}

/** A tree cache over a map; `failure` makes every call throw. */
export class FakeTreeCache implements TreeCache {
  readonly items = new Map<string, unknown>();
  failure: Error | undefined;

  get<T>(key: string): Promise<T | undefined> {
    return this.failure ? Promise.reject(this.failure) : Promise.resolve(this.items.get(key) as T);
  }

  set(key: string, value: unknown): Promise<void> {
    this.items.set(key, value);
    return this.failure ? Promise.reject(this.failure) : Promise.resolve();
  }
}
