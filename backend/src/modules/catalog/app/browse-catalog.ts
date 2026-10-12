import { Inject, Injectable } from '@nestjs/common';
import { DomainError } from '../../../platform/errors/domain-error';
import { type Service, servicesOf, type SubService } from '../domain/catalog';
import { CatalogReason } from '../domain/errors';
import { CATALOG_REPOSITORY, type CatalogRepository } from '../port/catalog-repository';
import { CatalogTree } from './catalog-tree';

/** A sub-service with its service, as copied onto a booking. */
export interface PriceSnapshot {
  readonly subService: SubService;
  readonly service: Service;
}

/** What the apps and other modules look up in the catalog. */
@Injectable()
export class BrowseCatalog {
  constructor(
    @Inject(CATALOG_REPOSITORY) private readonly repo: CatalogRepository,
    @Inject(CatalogTree) private readonly tree: CatalogTree,
  ) {}

  /** A published service with its published sub-services (C09). */
  async publishedService(id: string): Promise<Service> {
    const { categories } = await this.tree.published();
    const found = servicesOf(categories).find((s) => s.id === id);
    if (!found) {
      throw new DomainError(CatalogReason.NotFound);
    }
    return found;
  }

  /** Published services and sub-services matching Bangla or English text (C08). */
  async search(term: string): Promise<{ services: Service[]; subServices: SubService[] }> {
    const hits = await this.repo.search(term);
    const services = servicesOf((await this.tree.published()).categories);
    const serviceById = new Map(services.map((s) => [s.id, s]));
    const subById = new Map(services.flatMap((s) => s.subServices).map((ss) => [ss.id, ss]));
    return {
      services: present(hits.serviceIds.map((id) => serviceById.get(id))),
      subServices: present(hits.subServiceIds.map((id) => subById.get(id))),
    };
  }

  /** Every published service (contract `listServices`). */
  async publishedServices(): Promise<Service[]> {
    return servicesOf((await this.tree.published()).categories);
  }

  /** Any service, published or not (contract `getService`). */
  service(id: string): Promise<Service> {
    return this.repo.service(id);
  }

  /** The current price version of a sub-service (contract `getPriceSnapshot`). */
  async priceSnapshot(subServiceId: string): Promise<PriceSnapshot> {
    const subService = await this.repo.subService(subServiceId);
    return { subService, service: await this.repo.service(subService.serviceId) };
  }
}

// A hit can sit under an unpublished category or service, which the apps never see.
function present<T>(items: (T | undefined)[]): T[] {
  return items.filter((item): item is T => item !== undefined);
}
