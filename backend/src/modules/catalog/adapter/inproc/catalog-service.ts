import { Inject, Injectable } from '@nestjs/common';
import { DomainError, isDomainError } from '../../../../platform/errors/domain-error';
import { BrowseCatalog } from '../../app/browse-catalog';
import { type CatalogService } from '../../contract/catalog-service';
import {
  type PriceSnapshot,
  type PriceUnit,
  type Service,
  type ServiceModel,
} from '../../contract/dto';
import { CatalogErrors } from '../../contract/errors';
import { type Service as CatalogEntry } from '../../domain/catalog';
import { CatalogReason } from '../../domain/errors';

/** The catalog contract for other modules in the process. */
@Injectable()
export class InprocCatalogService implements CatalogService {
  constructor(@Inject(BrowseCatalog) private readonly browse: BrowseCatalog) {}

  async getService(serviceId: string): Promise<Service> {
    const service = await this.browse
      .service(serviceId)
      .catch(rethrowNotFoundAs(CatalogErrors.ServiceNotFound));
    return toContract(service);
  }

  async getPriceSnapshot(subServiceId: string): Promise<PriceSnapshot> {
    const { subService: sub, service } = await this.browse
      .priceSnapshot(subServiceId)
      .catch(rethrowNotFoundAs(CatalogErrors.SubServiceNotFound));
    return {
      subServiceId: sub.id,
      serviceId: sub.serviceId,
      priceVersionId: sub.priceVersionId,
      name: sub.name,
      unit: sub.unit as PriceUnit,
      amountPaisa: sub.price,
      maxQuantity: sub.maxQuantity,
      published: sub.published && service.published,
    };
  }

  async listServices(): Promise<Service[]> {
    return (await this.browse.publishedServices()).map(toContract);
  }
}

function rethrowNotFoundAs(reason: string): (err: unknown) => never {
  return (err) => {
    throw isDomainError(err, CatalogReason.NotFound)
      ? new DomainError(reason, { cause: err })
      : err;
  };
}

function toContract(s: CatalogEntry): Service {
  return {
    id: s.id,
    categoryId: s.categoryId,
    name: s.name,
    model: s.model as ServiceModel,
    requiredLevel: s.requiredLevel,
    searchRadiusM: s.searchRadiusM,
    womenProvidersOnly: s.womenProvidersOnly,
    requiresLevel2: s.requiresLevel2,
    level2Checklist: s.level2Checklist,
    published: s.published,
  };
}
