import { type components } from '../../../../platform/http/openapi.gen';
import { type Tree } from '../../app/catalog-tree';
import {
  type Category,
  type Name,
  type PriceVersion,
  type Service,
  type SubService,
} from '../../domain/catalog';

type Schemas = components['schemas'];

/** The API shape of a catalog tree. */
export function treeView(t: Tree): Schemas['CatalogTree'] {
  return { version: t.version, categories: t.categories.map(categoryView) };
}

/** The API shape of a category with its services. */
export function categoryView(c: Category): Schemas['Category'] {
  return {
    id: c.id,
    name: c.name,
    iconKey: c.iconKey,
    sortOrder: c.sortOrder,
    published: c.published,
    services: c.services.map(serviceView),
  };
}

/** The API shape of a service with its sub-services. */
export function serviceView(s: Service): Schemas['Service'] {
  return {
    id: s.id,
    categoryId: s.categoryId,
    name: s.name,
    iconKey: s.iconKey,
    serviceModel: s.model as Schemas['ServiceModel'],
    requiredLevel: s.requiredLevel,
    searchRadiusM: s.searchRadiusM,
    womenProvidersOnly: s.womenProvidersOnly,
    requiresLevel2: s.requiresLevel2,
    level2Checklist: [...s.level2Checklist],
    published: s.published,
    subServices: s.subServices.map(subServiceView),
  };
}

/** The API shape of a sub-service with its current price. */
export function subServiceView(s: SubService): Schemas['SubService'] {
  return {
    id: s.id,
    serviceId: s.serviceId,
    name: s.name,
    description: s.description,
    inclusions: [...s.inclusions],
    exclusions: [...s.exclusions],
    unit: s.unit as Schemas['PriceUnit'],
    price: s.price,
    priceVersionId: s.priceVersionId,
    maxQuantity: s.maxQuantity,
    published: s.published,
  };
}

/** The API shape of a price version. */
export function priceView(p: PriceVersion): Schemas['PriceVersion'] {
  return {
    id: p.id,
    subServiceId: p.subServiceId,
    amount: p.amount,
    effectiveFrom: p.effectiveFrom.toISOString(),
    createdBy: p.createdBy,
  };
}

const names = (texts: readonly Name[] | undefined): Name[] => [...(texts ?? [])];

/** A category to save, from the API input. */
export function categoryInput(id: string | undefined, input: Schemas['CategoryInput']) {
  return {
    id,
    name: input.name,
    iconKey: input.iconKey,
    sortOrder: input.sortOrder ?? 0,
    published: input.published ?? false,
  };
}

/** A service to save, from the API input. */
export function serviceInput(id: string | undefined, input: Schemas['ServiceInput']) {
  return {
    id,
    categoryId: input.categoryId,
    name: input.name,
    iconKey: input.iconKey,
    model: input.serviceModel,
    requiredLevel: input.requiredLevel,
    searchRadiusM: input.searchRadiusM,
    womenProvidersOnly: input.womenProvidersOnly ?? false,
    requiresLevel2: input.requiresLevel2 ?? false,
    level2Checklist: names(input.level2Checklist),
    sortOrder: 0,
    published: input.published ?? false,
  };
}

/** A sub-service to save, from the API input; its price is set separately. */
export function subServiceInput(input: Schemas['SubServiceInput']) {
  return {
    serviceId: input.serviceId,
    name: input.name,
    description: input.description ?? { en: '', bn: '' },
    inclusions: names(input.inclusions),
    exclusions: names(input.exclusions),
    unit: input.unit,
    maxQuantity: input.maxQuantity ?? 1,
    sortOrder: 0,
    published: input.published ?? false,
  };
}
