import { type Clock } from '../../../../platform/clock/clock';
import { type SqlClient } from '../../../../platform/db/database';
import { type OutboxWriter } from '../../../../platform/outbox/outbox';
import { type CatalogEvent } from '../../contract/events';
import {
  type CategoryFields,
  type PriceVersion,
  type ServiceFields,
  type SubServiceFields,
} from '../../domain/catalog';
import { type CatalogWriter } from '../../port/catalog-repository';
import { toNumber } from './rows';
import * as sql from './sqlc/queries_sql';

/** Writes catalog rows and outbox events on one transaction's client. */
export class PostgresCatalogWriter implements CatalogWriter {
  constructor(
    private readonly tx: SqlClient,
    private readonly outbox: OutboxWriter,
    private readonly clock: Clock,
  ) {}

  async saveCategory(c: CategoryFields): Promise<void> {
    const now = this.clock.now();
    await this.tx.query(sql.upsertCategoryQuery, [
      c.id,
      c.name.en,
      c.name.bn,
      c.iconKey,
      c.sortOrder,
      c.published,
      now,
    ]);
  }

  async saveService(s: ServiceFields): Promise<void> {
    await this.tx.query(sql.upsertServiceQuery, [
      s.id,
      s.categoryId,
      s.name.en,
      s.name.bn,
      s.iconKey,
      s.model,
      s.requiredLevel,
      s.searchRadiusM,
      s.womenProvidersOnly,
      s.requiresLevel2,
      JSON.stringify(s.level2Checklist),
      s.sortOrder,
      s.published,
      this.clock.now(),
    ]);
  }

  async saveSubService(s: SubServiceFields): Promise<void> {
    await this.tx.query(sql.upsertSubServiceQuery, [
      s.id,
      s.serviceId,
      s.name.en,
      s.name.bn,
      JSON.stringify(s.description),
      JSON.stringify(s.inclusions),
      JSON.stringify(s.exclusions),
      s.unit,
      s.maxQuantity,
      s.sortOrder,
      s.published,
      this.clock.now(),
    ]);
  }

  addPrice(p: PriceVersion): Promise<void> {
    return sql.addPrice(this.tx, {
      id: p.id,
      subServiceId: p.subServiceId,
      amountPaisa: String(p.amount),
      effectiveFrom: p.effectiveFrom,
      createdBy: p.createdBy,
    });
  }

  async bumpVersion(): Promise<number> {
    const row = await sql.bumpVersion(this.tx);
    return toNumber(row?.version ?? '0');
  }

  publish(aggregateId: string, event: CatalogEvent): Promise<void> {
    return this.outbox.write(this.tx, aggregateId, event);
  }
}
