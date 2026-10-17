import { escapeIdentifier } from 'pg';
import { type Clock } from '../clock/clock';
import { type Database, type SqlClient } from '../db/database';
import { type DomainEvent } from '../events/domain-event';
import { type Envelope, type EventHandler } from '../events/event-bus';
import { type IdGenerator } from '../ids/id-generator';

/** The quoted `"<module>"."<name>"`; module names only ever come from code. */
export function moduleTable(module: string, name: string): string {
  return `${escapeIdentifier(module)}.${escapeIdentifier(name)}`;
}

/**
 * Appends events to a module's outbox inside the caller's transaction, so an event is
 * stored exactly when the change that caused it commits (PRD §9.3 rule 5).
 */
export class OutboxWriter {
  private readonly table: string;

  constructor(
    private readonly module: string,
    private readonly ids: IdGenerator,
    private readonly clock: Clock,
  ) {
    this.table = moduleTable(module, 'outbox');
  }

  /** Stores `event` for `aggregateId` on `tx`. */
  async write(tx: SqlClient, aggregateId: string, event: DomainEvent): Promise<void> {
    let payload: string;
    try {
      payload = JSON.stringify(event);
    } catch (cause) {
      throw new Error(`encode ${event.name}`, { cause });
    }
    try {
      await tx.query(
        `INSERT INTO ${this.table} (id, aggregate_id, event_name, payload, created_at, next_attempt_at) VALUES ($1, $2, $3, $4, $5, $5)`,
        [this.ids.newId(), aggregateId, event.name, payload, this.clock.now()],
      );
    } catch (cause) {
      throw new Error(`write ${event.name} to ${this.module} outbox`, { cause });
    }
  }
}

/** Handles an event inside the subscribing module's transaction. */
export type TxEventHandler<E extends DomainEvent> = (
  tx: SqlClient,
  env: Envelope<E>,
) => Promise<void>;

/**
 * Wraps `handler` so each event is applied once per handler: the processed-event row
 * and the handler's writes commit together, and a redelivered event is skipped.
 */
export function idempotentHandler<E extends DomainEvent>(
  db: Database,
  module: string,
  handlerName: string,
  handler: TxEventHandler<E>,
): EventHandler<E> {
  const table = moduleTable(module, 'processed_events');
  return (env) =>
    db.transaction(async (tx) => {
      let inserted: number | null;
      try {
        const res = await tx.query(
          `INSERT INTO ${table} (handler, event_id) VALUES ($1, $2) ON CONFLICT DO NOTHING`,
          [handlerName, env.id],
        );
        inserted = res.rowCount;
      } catch (cause) {
        throw new Error(`mark ${env.id} processed by ${handlerName}`, { cause });
      }
      if (inserted !== 0) {
        await handler(tx, env);
      }
    });
}

/** Delivered events are kept a week; dead letters stay for inspection. */
export const OUTBOX_RETENTION_MS = 7 * 24 * 60 * 60 * 1000;

/** Deletes events delivered before `cutoff` from the modules' outboxes. */
export async function purgePublishedEvents(
  db: Database,
  modules: readonly string[],
  cutoff: Date,
): Promise<void> {
  for (const module of modules) {
    const table = moduleTable(module, 'outbox');
    try {
      await db.query(`DELETE FROM ${table} WHERE published_at < $1`, [cutoff]);
    } catch (cause) {
      throw new Error(`purge ${table}`, { cause });
    }
  }
}

/** One module's undelivered events, as the worker's metrics report them. */
export interface OutboxBacklog {
  readonly module: string;
  readonly pending: number;
  readonly dead: number;
  /** Age of the oldest pending event; 0 when nothing waits. */
  readonly oldestSeconds: number;
}

/** Reads each module's outbox backlog as of `now`. */
export async function readOutboxBacklog(
  db: Database,
  modules: readonly string[],
  now: Date,
): Promise<OutboxBacklog[]> {
  const backlog: OutboxBacklog[] = [];
  for (const module of modules) {
    const table = moduleTable(module, 'outbox');
    try {
      const { rows } = await db.query<{ pending: number; dead: number; oldest: Date | null }>(
        `SELECT count(*) FILTER (WHERE NOT dead)::int AS pending, count(*) FILTER (WHERE dead)::int AS dead,
                min(created_at) FILTER (WHERE NOT dead) AS oldest
         FROM ${table} WHERE published_at IS NULL`,
      );
      const { pending = 0, dead = 0, oldest = null } = rows[0] ?? {};
      const age = oldest ? Math.max(0, now.getTime() - oldest.getTime()) / 1000 : 0;
      backlog.push({ module, pending, dead, oldestSeconds: age });
    } catch (cause) {
      throw new Error(`read backlog of ${table}`, { cause });
    }
  }
  return backlog;
}
