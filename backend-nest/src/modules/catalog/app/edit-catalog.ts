import { Inject, Injectable } from '@nestjs/common';
import { CLOCK, type Clock } from '../../../platform/clock/clock';
import { DomainError } from '../../../platform/errors/domain-error';
import { ID_GENERATOR, type IdGenerator } from '../../../platform/ids/id-generator';
import {
  type Category,
  type CategoryFields,
  isValidCategory,
  isValidPrice,
  isValidService,
  isValidSubService,
  type Service,
  type ServiceFields,
  type SubService,
  type SubServiceFields,
} from '../domain/catalog';
import { CatalogReason } from '../domain/errors';
import { CATALOG_REPOSITORY, type CatalogRepository } from '../port/catalog-repository';
import { check } from './check';
import { recordChange } from './record-change';

/** Fields of an item to save; without an id it is created. */
export type Draft<T extends { id: string }> = Omit<T, 'id'> & { readonly id?: string };

/** Admin edits of categories, services and sub-services (A-02). */
@Injectable()
export class EditCatalog {
  constructor(
    @Inject(CATALOG_REPOSITORY) private readonly repo: CatalogRepository,
    @Inject(CLOCK) private readonly clock: Clock,
    @Inject(ID_GENERATOR) private readonly ids: IdGenerator,
  ) {}

  /** Creates or updates a category. */
  async saveCategory(draft: Draft<CategoryFields>): Promise<Category> {
    check(isValidCategory(draft), CatalogReason.Invalid);
    if (draft.id !== undefined) {
      await this.categoryMustExist(draft.id);
    }
    const category = { ...draft, id: draft.id ?? this.ids.newId() };
    await recordChange(this.repo, (w) => w.saveCategory(category));
    return { ...category, services: [] };
  }

  /** Creates or updates a service in an existing category. */
  async saveService(draft: Draft<ServiceFields>): Promise<Service> {
    const service = { ...draft, id: draft.id ?? this.ids.newId() };
    check(isValidService(service), CatalogReason.Invalid);
    await this.categoryMustExist(service.categoryId);
    if (draft.id !== undefined) {
      await this.repo.service(draft.id);
    }
    await recordChange(this.repo, (w) => w.saveService(service));
    return this.repo.service(service.id);
  }

  /** Adds a sub-service with its first price, set by `actorId`. */
  async createSubService(
    draft: Omit<SubServiceFields, 'id'>,
    price: number,
    actorId: string,
  ): Promise<SubService> {
    await this.checkSubService(draft, price);
    const sub = { ...draft, id: this.ids.newId() };
    const firstPrice = {
      id: this.ids.newId(),
      subServiceId: sub.id,
      amount: price,
      effectiveFrom: this.clock.now(),
      createdBy: actorId,
    };
    await recordChange(this.repo, async (w) => {
      await w.saveSubService(sub);
      await w.addPrice(firstPrice);
    });
    return this.repo.subService(sub.id);
  }

  /** Edits a sub-service; its price changes only through a new price version. */
  async updateSubService(sub: SubServiceFields): Promise<SubService> {
    await this.checkSubService(sub, 0);
    await this.repo.subService(sub.id);
    await recordChange(this.repo, (w) => w.saveSubService(sub));
    return this.repo.subService(sub.id);
  }

  private async checkSubService(sub: Omit<SubServiceFields, 'id'>, price: number): Promise<void> {
    check(isValidSubService(sub), CatalogReason.Invalid);
    check(isValidPrice(price), CatalogReason.PriceNegative);
    await this.repo.service(sub.serviceId);
  }

  private async categoryMustExist(id: string): Promise<void> {
    if (!(await this.repo.categoryExists(id))) {
      throw new DomainError(CatalogReason.NotFound);
    }
  }
}
