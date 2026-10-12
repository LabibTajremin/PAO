import { Inject, Injectable } from '@nestjs/common';
import { DATABASE, type Database, type SqlClient } from '../../../../platform/db/database';
import { type Envelope, type EventBus } from '../../../../platform/events/event-bus';
import { idempotentHandler } from '../../../../platform/outbox/outbox';
import { WorkerHooksProvider, type WorkerHooks } from '../../../../platform/worker/worker-hooks';
import { BookingEvents } from '../../../booking/contract/events';
import { Role } from '../../../identity/contract/dto';
import { IdentityEvents } from '../../../identity/contract/events';
import { eraseCustomer } from './customer-repository';
import { countCustomerBooking, setCustomerStatus } from './sqlc/queries_sql';

type Apply = (tx: SqlClient, env: Envelope) => Promise<void>;

/** Reads a field the handler needs; a malformed event fails so the relay retries it. */
function field<T>(env: Envelope, name: string, ok: (v: unknown) => v is T): T {
  const value = (env.payload as unknown as Readonly<Record<string, unknown>>)[name];
  if (!ok(value)) {
    throw new Error(`decode ${env.name}: ${name} is missing`);
  }
  return value;
}

const isString = (v: unknown): v is string => typeof v === 'string';
const isList = (v: unknown): v is unknown[] => Array.isArray(v);

// Keyed by handler name in processed_events; the names are Go's, so redelivered events
// already applied by the Go worker stay skipped.
const handlers: Readonly<Record<string, [event: string, apply: Apply]>> = {
  erase_account: [
    IdentityEvents.AccountDeleted,
    (tx, env) => eraseCustomer(tx, field(env, 'accountId', isString)),
  ],
  [IdentityEvents.AccountStatusChanged]: [
    IdentityEvents.AccountStatusChanged,
    async (tx, env) => {
      const id = field(env, 'accountId', isString);
      const accountStatus = field(env, 'to', isString);
      if (field(env, 'roles', isList).includes(Role.Customer)) {
        await setCustomerStatus(tx, { id, accountStatus });
      }
    },
  ],
  [BookingEvents.BookingRequested]: [
    BookingEvents.BookingRequested,
    // Like Go, which decoded a missing id as the nil UUID: the count touches no row.
    async (tx, env) => {
      const id = (env.payload as unknown as { customerId?: unknown }).customerId;
      if (isString(id)) {
        await countCustomerBooking(tx, { id });
      }
    },
  ],
};

/** Erases deleted accounts and keeps the admin list copies (status, bookings) current. */
@Injectable()
@WorkerHooksProvider()
export class CustomerSubscribers implements WorkerHooks {
  constructor(@Inject(DATABASE) private readonly db: Database) {}

  subscribe(bus: EventBus): void {
    for (const [handler, [event, apply]] of Object.entries(handlers)) {
      bus.subscribe(event, 'customer', idempotentHandler(this.db, 'customer', handler, apply));
    }
  }
}
