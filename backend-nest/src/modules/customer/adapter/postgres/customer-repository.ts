import { Inject, Injectable } from '@nestjs/common';
import { CLOCK, type Clock } from '../../../../platform/clock/clock';
import { DATABASE, type Database, type SqlClient } from '../../../../platform/db/database';
import { DomainError } from '../../../../platform/errors/domain-error';
import { type DomainEvent } from '../../../../platform/events/domain-event';
import { ID_GENERATOR, type IdGenerator } from '../../../../platform/ids/id-generator';
import { OutboxWriter } from '../../../../platform/outbox/outbox';
import { CustomerReasons } from '../../app/errors';
import { type CustomerQuery, type CustomerRecord } from '../../contract/admin-search';
import { type Customer } from '../../domain/customer';
import { type StoredCustomer } from '../../port/repository';
import { AddressStore } from './address-store';
import { customerByID, deleteCustomer, searchCustomers, upsertCustomer } from './sqlc/queries_sql';

const NIL_UUID = '00000000-0000-0000-0000-000000000000';

/** Keeps admin search text literal inside a LIKE pattern. */
function likePattern(text: string): string {
  const t = text.trim().toLowerCase();
  return t === '' ? '' : `%${t.replace(/[\\%_]/g, (c) => `\\${c}`)}%`;
}

/** Erases a customer and, by cascade, their addresses (account deletion, PRD §11). */
export function eraseCustomer(tx: SqlClient, id: string): Promise<void> {
  return deleteCustomer(tx, { id });
}

/** The customer schema on PostGIS. */
@Injectable()
export class PostgresCustomerRepository extends AddressStore {
  private readonly outbox: OutboxWriter;

  constructor(
    @Inject(DATABASE) db: Database,
    @Inject(ID_GENERATOR) ids: IdGenerator,
    @Inject(CLOCK) clock: Clock,
  ) {
    super(db);
    this.outbox = new OutboxWriter('customer', ids, clock);
  }

  saveCustomer(c: StoredCustomer, event: DomainEvent): Promise<void> {
    return this.db.transaction(async (tx) => {
      await upsertCustomer(tx, {
        id: c.id,
        name: c.name,
        photoMediaId: c.photoMediaId,
        language: c.language,
        createdAt: c.updatedAt,
        phone: c.phone,
        accountStatus: c.status,
      });
      await this.outbox.write(tx, c.id, event);
    });
  }

  async getCustomer(id: string): Promise<Customer> {
    const row = await customerByID(this.db.pool, { id });
    if (row === null) {
      throw new DomainError(CustomerReasons.NotFound);
    }
    return row;
  }

  async search(q: CustomerQuery): Promise<CustomerRecord[]> {
    const rows = await searchCustomers(this.db.pool, {
      id: q.id,
      pattern: likePattern(q.text),
      status: q.status === '' ? null : q.status,
      beforeAt: q.afterAt,
      beforeId: q.afterId ?? NIL_UUID,
      maxRows: String(q.limit),
    });
    return rows.map((r) => ({
      id: r.id,
      name: r.name,
      phone: r.phone,
      status: r.accountStatus,
      bookings: r.bookings,
      createdAt: r.createdAt,
    }));
  }
}
