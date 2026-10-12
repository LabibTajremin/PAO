import { type Name, type ServiceFields, type SubService } from '../../domain/catalog';
import { type ServiceByIDRow, type SubServiceByIDRow } from './sqlc/queries_sql';

/** Postgres `bigint` arrives as a string; paisa and versions always fit a safe integer. */
export function toNumber(value: string): number {
  const n = Number(value);
  if (!Number.isSafeInteger(n)) {
    throw new Error(`not a safe integer: ${value}`);
  }
  return n;
}

/** A services row as a service without its sub-services. */
export function toService(row: ServiceByIDRow): ServiceFields {
  return {
    id: row.id,
    categoryId: row.categoryId,
    name: { en: row.nameEn, bn: row.nameBn },
    iconKey: row.iconKey,
    model: row.serviceModel,
    requiredLevel: row.requiredLevel,
    searchRadiusM: row.searchRadiusM,
    womenProvidersOnly: row.womenProvidersOnly,
    requiresLevel2: row.requiresLevel_2,
    level2Checklist: row.level2Checklist as Name[],
    sortOrder: row.sortOrder,
    published: row.published,
  };
}

/** A sub_services row joined with its current price. */
export function toSubService(row: SubServiceByIDRow): SubService {
  return {
    id: row.id,
    serviceId: row.serviceId,
    name: { en: row.nameEn, bn: row.nameBn },
    description: row.description as Name,
    inclusions: row.inclusions as Name[],
    exclusions: row.exclusions as Name[],
    unit: row.unit,
    maxQuantity: row.maxQuantity,
    sortOrder: row.sortOrder,
    published: row.published,
    priceVersionId: row.priceVersionId,
    price: toNumber(row.amountPaisa),
  };
}

/** Groups items by a key, keeping their order. */
export function groupBy<T>(items: readonly T[], key: (item: T) => string): Map<string, T[]> {
  const groups = new Map<string, T[]>();
  for (const item of items) {
    const group = groups.get(key(item));
    if (group) {
      group.push(item);
    } else {
      groups.set(key(item), [item]);
    }
  }
  return groups;
}
