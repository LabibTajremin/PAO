import { Inject, Injectable } from '@nestjs/common';
import { DATABASE, type Database, type SqlClient } from '../../../../platform/db/database';
import { type Envelope, type EventBus } from '../../../../platform/events/event-bus';
import { idempotentHandler } from '../../../../platform/outbox/outbox';
import { WorkerHooksProvider, type WorkerHooks } from '../../../../platform/worker/worker-hooks';
import { BookingEvents } from '../../../booking/contract/events';
import { Role } from '../../../identity/contract/dto';
import { IdentityEvents } from '../../../identity/contract/events';
import { VerificationEvents } from '../../../verification/contract/events';
import { dhakaDate } from '../../app/read-dashboard';
import { sqlDate } from './dashboard-repository';
import {
  addStatsProvider,
  bumpBookings,
  deleteStatsProvider,
  setStatsLevel,
  setStatsStatus,
} from './sqlc/queries_sql';

type Payload = Readonly<Record<string, unknown>>;
type Apply = (tx: SqlClient, env: Envelope) => Promise<void>;

/** Reads a field the handler needs; a malformed event fails so the relay retries it. */
function field<T>(env: Envelope, name: string, ok: (v: unknown) => v is T): T {
  const value = (env.payload as unknown as Payload)[name];
  if (!ok(value)) {
    throw new Error(`decode ${env.name}: ${name} is missing`);
  }
  return value;
}

const isString = (v: unknown): v is string => typeof v === 'string';
const isNumber = (v: unknown): v is number => Number.isInteger(v);
const isList = (v: unknown): v is unknown[] => Array.isArray(v);

function bump(requested: number, completed: number): Apply {
  return (tx, env) =>
    bumpBookings(tx, { day: sqlDate(dhakaDate(env.occurredAt)), requested, completed });
}

const handlers: Readonly<Record<string, Apply>> = {
  [IdentityEvents.AccountCreated]: async (tx, env) => {
    const providerId = field(env, 'accountId', isString);
    if (field(env, 'role', isString) === Role.Provider) {
      await addStatsProvider(tx, { providerId });
    }
  },
  [IdentityEvents.AccountStatusChanged]: async (tx, env) => {
    const providerId = field(env, 'accountId', isString);
    const status = field(env, 'to', isString);
    if (field(env, 'roles', isList).includes(Role.Provider)) {
      await setStatsStatus(tx, { providerId, status });
    }
  },
  [IdentityEvents.AccountDeleted]: (tx, env) =>
    deleteStatsProvider(tx, { providerId: field(env, 'accountId', isString) }),
  [VerificationEvents.ProviderLevelChanged]: (tx, env) =>
    setStatsLevel(tx, {
      providerId: field(env, 'providerId', isString),
      level: field(env, 'to', isNumber),
    }),
  [BookingEvents.BookingRequested]: bump(1, 0),
  [BookingEvents.BookingCompleted]: bump(0, 1),
};

/** Keeps the dashboard read model current from other modules' events (A-09). */
@Injectable()
@WorkerHooksProvider()
export class StatsSubscribers implements WorkerHooks {
  constructor(@Inject(DATABASE) private readonly db: Database) {}

  subscribe(bus: EventBus): void {
    for (const [name, apply] of Object.entries(handlers)) {
      bus.subscribe(name, 'admin', idempotentHandler(this.db, 'admin', name, apply));
    }
  }
}
