import { Inject, Injectable, type Provider } from '@nestjs/common';
import { CLOCK, type Clock } from '../../../../platform/clock/clock';
import {
  DATABASE,
  type Database,
  isUniqueViolation,
  type SqlClient,
} from '../../../../platform/db/database';
import { DomainError } from '../../../../platform/errors/domain-error';
import { type DomainEvent } from '../../../../platform/events/domain-event';
import { ID_GENERATOR, type IdGenerator } from '../../../../platform/ids/id-generator';
import { OutboxWriter } from '../../../../platform/outbox/outbox';
import { type Booking } from '../../domain/booking';
import { BookingReasons } from '../../domain/reasons';
import {
  type BookingRepository,
  type Change,
  type DayTotal,
  type EarningsJob,
  type Filter,
  type Page,
  type Range,
  type Summary,
} from '../../port/repository';
import { load, saveParts, toSummary, update } from './rows';
import {
  adminListBookings,
  bookingIDByKey,
  countActive,
  dueRequests,
  earningsByDay,
  earningsJobs,
  insertBooking,
  listBookings,
  lockBooking,
  lockProvider,
  providerStats,
} from './sqlc/queries_sql';

/** The booking module's outbox writer. */
export type BookingOutbox = Pick<OutboxWriter, 'write'>;

/** Injection token for the {@link BookingOutbox}. */
export const BOOKING_OUTBOX = Symbol('BookingOutbox');

/** Provides the writer for `booking.outbox`. */
export const bookingOutboxProvider: Provider = {
  provide: BOOKING_OUTBOX,
  inject: [ID_GENERATOR, CLOCK],
  useFactory: (ids: IdGenerator, clock: Clock) => new OutboxWriter('booking', ids, clock),
};

// Keyset queries ignore the id without a time; any uuid satisfies the parameter type.
const NO_ID = '00000000-0000-0000-0000-000000000000';

function keyset(p: Page) {
  return { beforeAt: p.at, beforeId: p.id ?? NO_ID, maxRows: String(p.limit) };
}

/** The booking schema on PostGIS. */
@Injectable()
export class PostgresBookingRepository implements BookingRepository {
  constructor(
    @Inject(DATABASE) private readonly db: Database,
    @Inject(BOOKING_OUTBOX) private readonly outbox: BookingOutbox,
    @Inject(CLOCK) private readonly clock: Clock,
  ) {}

  async create(b: Booking, event: (b: Booking) => DomainEvent) {
    try {
      await this.db.transaction(async (tx) => {
        const row = await insertBooking(tx, insertArgs(b));
        b.number = Number(row?.number);
        await saveParts(tx, b);
        await this.outbox.write(tx, b.id, event(b));
      });
      return { booking: b, created: true };
    } catch (err) {
      if (isUniqueViolation(err, 'bookings_customer_id_idempotency_key_key')) {
        const key = { customerId: b.customer.id, idempotencyKey: b.idempotencyKey };
        const stored = await bookingIDByKey(this.db.pool, key);
        return { booking: await this.get(stored?.id ?? b.id), created: false };
      }
      if (isUniqueViolation(err, 'bookings_one_request_per_pair')) {
        throw new DomainError(BookingReasons.DuplicateRequest, { cause: err });
      }
      throw err;
    }
  }

  get(id: string): Promise<Booking> {
    return this.load(this.db.pool, id);
  }

  change(id: string, fn: Change): Promise<Booking> {
    return this.db.transaction(async (tx) => {
      const locked = await lockBooking(tx, { id });
      if (locked === null) {
        throw new DomainError(BookingReasons.NotFound);
      }
      await lockProvider(tx, locked);
      const b = await this.load(tx, id);
      const active = await countActive(tx, { providerId: locked.providerId, exceptId: id });
      b.providerActiveJobs = Number(active?.count);
      const events = await fn(b);
      await update(tx, b, this.clock.now());
      for (const e of events) {
        await this.outbox.write(tx, id, e);
      }
      return b;
    });
  }

  private async load(db: SqlClient, id: string): Promise<Booking> {
    const b = await load(db, id);
    if (b === undefined) {
      throw new DomainError(BookingReasons.NotFound);
    }
    return b;
  }

  async list(
    party: { id: string; asProvider: boolean },
    statuses: readonly string[],
    p: Page,
  ): Promise<Summary[]> {
    const rows = await listBookings(this.db.pool, {
      asProvider: party.asProvider,
      partyId: party.id,
      statuses: [...statuses],
      ...keyset(p),
    });
    return rows.map(toSummary);
  }

  async monitor(f: Filter, p: Page): Promise<Summary[]> {
    const rows = await adminListBookings(this.db.pool, {
      ...f,
      fromAt: f.from,
      untilAt: f.until,
      ...keyset(p),
    });
    return rows.map(toSummary);
  }

  async due(now: Date): Promise<string[]> {
    return (await dueRequests(this.db.pool, { acceptDeadline: now })).map((r) => r.id);
  }

  async earningsByDay(providerId: string, r: Range): Promise<DayTotal[]> {
    const rows = await earningsByDay(this.db.pool, {
      providerId,
      fromAt: r.from,
      untilAt: r.until,
    });
    // pg reads a date as local midnight; its calendar fields are the Dhaka date.
    return rows.map((row) => ({
      day: new Date(Date.UTC(row.day.getFullYear(), row.day.getMonth(), row.day.getDate())),
      total: Number(row.total),
      jobs: row.jobs,
    }));
  }

  async earningsJobs(providerId: string, r: Range, p: Page): Promise<EarningsJob[]> {
    const rows = await earningsJobs(this.db.pool, {
      providerId,
      fromAt: r.from,
      untilAt: r.until,
      ...keyset(p),
    });
    return rows.map((row) => ({
      ...row,
      number: Number(row.number),
      serviceName: { en: row.serviceNameEn, bn: row.serviceNameBn },
      totalPaisa: Number(row.totalPaisa),
    }));
  }

  async stats(providerId: string, since: Date) {
    const row = await providerStats(this.db.pool, { providerId, since });
    return { completed: row?.completed ?? 0, cancellations: row?.cancellations ?? 0 };
  }

  async countActive(providerId: string): Promise<number> {
    return Number((await countActive(this.db.pool, { providerId, exceptId: NO_ID }))?.count);
  }
}

function insertArgs(b: Booking) {
  return {
    ...b,
    customerId: b.customer.id,
    providerId: b.provider.id,
    serviceNameEn: b.serviceName.en,
    serviceNameBn: b.serviceName.bn,
    customerName: b.customer.name,
    customerPhone: b.customer.phone,
    providerName: b.provider.name,
    providerPhone: b.provider.phone,
    addressId: b.address.id,
    addressArea: b.address.area,
    addressLine1: b.address.line1,
    addressLine2: b.address.line2,
    lng: b.address.location.lng,
    lat: b.address.location.lat,
    timing: b.scheduled ? 'scheduled' : 'asap',
    totalPaisa: String(b.totalPaisa),
  };
}
