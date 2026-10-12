import { Inject, Injectable } from '@nestjs/common';
import { NIL as NIL_UUID } from 'uuid';
import { seedId } from '../contract/seed-ids';
import { CLOCK, type Clock } from '../../../platform/clock/clock';
import { isDomainError } from '../../../platform/errors/domain-error';
import { ID_GENERATOR, type IdGenerator } from '../../../platform/ids/id-generator';
import {
  type CatalogSeeder,
  type SeedCategory,
  type SeedService,
  type SeedSubService,
} from '../../../platform/seeding/seeders';
import { isValidService } from '../domain/catalog';
import { CatalogReason } from '../domain/errors';
import {
  CATALOG_REPOSITORY,
  type CatalogRepository,
  type CatalogWriter,
} from '../port/catalog-repository';
import { check } from './check';
import { recordChange } from './record-change';

export { seedId } from '../contract/seed-ids';

/**
 * Loads the MVP catalog idempotently (P04 task 3), every item published in file order.
 * A changed price inserts a new version; unchanged prices are left alone.
 */
@Injectable()
export class SeedCatalog implements CatalogSeeder {
  constructor(
    @Inject(CATALOG_REPOSITORY) private readonly repo: CatalogRepository,
    @Inject(CLOCK) private readonly clock: Clock,
    @Inject(ID_GENERATOR) private readonly ids: IdGenerator,
  ) {}

  seedCatalog(categories: readonly SeedCategory[]): Promise<void> {
    return recordChange(this.repo, async (w) => {
      for (const [sortOrder, c] of categories.entries()) {
        const id = seedId('category', c.key);
        await w.saveCategory({ id, name: c.name, iconKey: c.icon, sortOrder, published: true });
        for (const [order, s] of c.services.entries()) {
          await this.seedService(w, id, s, order);
        }
      }
    });
  }

  private async seedService(
    w: CatalogWriter,
    categoryId: string,
    s: SeedService,
    sortOrder: number,
  ): Promise<void> {
    const service = {
      id: seedId('service', s.key),
      categoryId,
      name: s.name,
      iconKey: s.icon,
      model: s.model,
      requiredLevel: s.requiredLevel,
      searchRadiusM: s.searchRadiusM,
      womenProvidersOnly: s.womenProvidersOnly,
      requiresLevel2: s.requiresLevel2,
      level2Checklist: s.level2Checklist,
      sortOrder,
      published: true,
    };
    check(isValidService(service), CatalogReason.Invalid);
    await w.saveService(service);
    for (const [order, sub] of s.subServices.entries()) {
      await this.seedSubService(w, service.id, sub, order);
    }
  }

  private async seedSubService(
    w: CatalogWriter,
    serviceId: string,
    sub: SeedSubService,
    sortOrder: number,
  ): Promise<void> {
    const id = seedId('sub-service', sub.key);
    await w.saveSubService({
      id,
      serviceId,
      name: sub.name,
      description: { en: '', bn: '' },
      inclusions: [],
      exclusions: [],
      unit: sub.unit,
      maxQuantity: sub.maxQuantity,
      sortOrder,
      published: true,
    });
    if ((await this.committedPrice(id)) === sub.pricePaisa) {
      return;
    }
    await w.addPrice({
      id: this.ids.newId(),
      subServiceId: id,
      amount: sub.pricePaisa,
      effectiveFrom: this.clock.now(),
      createdBy: NIL_UUID,
    });
  }

  // Read outside the seed's transaction: the price a previous seed committed, if any.
  private async committedPrice(id: string): Promise<number | undefined> {
    try {
      return (await this.repo.subService(id)).price;
    } catch (err) {
      if (isDomainError(err, CatalogReason.NotFound)) {
        return undefined;
      }
      throw err;
    }
  }
}
