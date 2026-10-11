import { Inject, Injectable } from '@nestjs/common';
import { CLOCK, type Clock } from '../../../../platform/clock/clock';
import { DATABASE, type Database } from '../../../../platform/db/database';
import { DomainError } from '../../../../platform/errors/domain-error';
import { ID_GENERATOR, type IdGenerator } from '../../../../platform/ids/id-generator';
import { OutboxWriter } from '../../../../platform/outbox/outbox';
import {
  type Category,
  type PriceVersion,
  type Service,
  type SubService,
} from '../../domain/catalog';
import { CatalogReason } from '../../domain/errors';
import {
  type CatalogRepository,
  type CatalogWriter,
  type SearchHits,
} from '../../port/catalog-repository';
import { groupBy, toNumber, toService, toSubService } from './rows';
import * as sql from './sqlc/queries_sql';
import { PostgresCatalogWriter } from './catalog-writer';

const notFound = (): DomainError => new DomainError(CatalogReason.NotFound);

/** The catalog repository on the `catalog` schema. */
@Injectable()
export class PostgresCatalogRepository implements CatalogRepository {
  private readonly outbox: OutboxWriter;

  constructor(
    @Inject(DATABASE) private readonly db: Database,
    @Inject(CLOCK) private readonly clock: Clock,
    @Inject(ID_GENERATOR) ids: IdGenerator,
  ) {
    this.outbox = new OutboxWriter('catalog', ids, clock);
  }

  /** Three queries, assembled in memory. */
  async tree(): Promise<Category[]> {
    const categories = await sql.categories(this.db.pool);
    const services = await sql.services(this.db.pool);
    const subs = groupBy(
      (await sql.subServices(this.db.pool)).map(toSubService),
      (s) => s.serviceId,
    );
    const servicesByCategory = groupBy(
      services.map((row) => ({ ...toService(row), subServices: subs.get(row.id) ?? [] })),
      (s) => s.categoryId,
    );
    return categories.map((c) => ({
      id: c.id,
      name: { en: c.nameEn, bn: c.nameBn },
      iconKey: c.iconKey,
      sortOrder: c.sortOrder,
      published: c.published,
      services: servicesByCategory.get(c.id) ?? [],
    }));
  }

  async categoryExists(id: string): Promise<boolean> {
    return (await sql.categoryExists(this.db.pool, { id }))?.exists === true;
  }

  async service(id: string): Promise<Service> {
    const row = await sql.serviceByID(this.db.pool, { id });
    if (!row) {
      throw notFound();
    }
    const subs = await sql.subServicesOfService(this.db.pool, { serviceId: id });
    return { ...toService(row), subServices: subs.map(toSubService) };
  }

  async subService(id: string): Promise<SubService> {
    const row = await sql.subServiceByID(this.db.pool, { id });
    if (!row) {
      throw notFound();
    }
    return toSubService(row);
  }

  async priceHistory(subServiceId: string): Promise<PriceVersion[]> {
    const rows = await sql.priceHistory(this.db.pool, { subServiceId });
    return rows.map((p) => ({
      id: p.id,
      subServiceId: p.subServiceId,
      amount: toNumber(p.amountPaisa),
      effectiveFrom: p.effectiveFrom,
      createdBy: p.createdBy,
    }));
  }

  async search(term: string): Promise<SearchHits> {
    const services = await sql.searchServices(this.db.pool, { term });
    const subs = await sql.searchSubServices(this.db.pool, { term });
    return { serviceIds: services.map((r) => r.id), subServiceIds: subs.map((r) => r.id) };
  }

  async version(): Promise<number> {
    const row = await sql.version(this.db.pool);
    return toNumber(row?.version ?? '0');
  }

  transaction<T>(fn: (w: CatalogWriter) => Promise<T>): Promise<T> {
    return this.db.transaction((tx) => fn(new PostgresCatalogWriter(tx, this.outbox, this.clock)));
  }
}
