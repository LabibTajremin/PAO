import { type PoolClient } from 'pg';
import { type Clock } from '../clock/clock';
import { type Database } from '../db/database';
import { type DomainEvent } from '../events/domain-event';
import { type Dispatcher, type Envelope } from '../events/event-bus';
import { Ticker } from '../jobs/ticker';
import { type Logger } from '../logging/logger';
import { moduleTable } from './outbox';

/** How often an event is tried before it is dead-lettered. */
export const MAX_ATTEMPTS = 10;

const BATCH = 100;
const MAX_BACKOFF_MS = 5 * 60 * 1000;

interface PendingRow {
  readonly env: Envelope;
  readonly attempts: number;
  readonly notBefore: Date;
}

interface OutboxRow {
  id: string;
  aggregate_id: string;
  event_name: string;
  payload: DomainEvent;
  created_at: Date;
  attempts: number;
  next_attempt_at: Date;
}

/**
 * Moves events from every module's outbox to the bus: at least once, in order per
 * aggregate, retrying with exponential backoff (capped at five minutes) and
 * dead-lettering after {@link MAX_ATTEMPTS}.
 */
export class OutboxRelay {
  private ticker?: Ticker;

  constructor(
    private readonly db: Database,
    private readonly bus: Dispatcher,
    private readonly modules: readonly string[],
    private readonly deps: { readonly clock: Clock; readonly log: Logger },
  ) {}

  /** Relays one batch from each module and returns how many events it delivered. */
  async runOnce(): Promise<number> {
    let total = 0;
    for (const module of this.modules) {
      try {
        total += await this.db.transaction((tx) => this.relayModule(tx, module));
      } catch (cause) {
        throw new Error(`relay ${module}`, { cause });
      }
    }
    return total;
  }

  /** Relays every `intervalMs` until {@link stop}. */
  start(intervalMs: number): void {
    this.ticker = new Ticker(
      () => intervalMs,
      () =>
        this.runOnce().then(
          () => undefined,
          (err: unknown) => {
            this.deps.log.error({ err }, 'outbox relay pass failed');
          },
        ),
    );
    this.ticker.start();
  }

  /** Stops relaying and waits for a pass in progress. */
  async stop(): Promise<void> {
    await this.ticker?.stop();
  }

  private async relayModule(tx: PoolClient, module: string): Promise<number> {
    const table = moduleTable(module, 'outbox');
    const rows = await this.pending(tx, module, table);
    const now = this.deps.clock.now();
    const blocked = new Set<string>();
    let delivered = 0;
    for (const row of rows) {
      // An aggregate's events stay in order: once one waits, later ones wait too.
      if (blocked.has(row.env.aggregateId) || row.notBefore > now) {
        blocked.add(row.env.aggregateId);
        continue;
      }
      const failure = await this.bus.dispatch(row.env).then(
        () => undefined,
        (err: unknown) => (err instanceof Error ? err : new Error(String(err))),
      );
      await this.record(tx, table, row, failure);
      if (failure) {
        blocked.add(row.env.aggregateId);
      } else {
        delivered++;
      }
    }
    return delivered;
  }

  private async pending(tx: PoolClient, module: string, table: string): Promise<PendingRow[]> {
    const { rows } = await tx.query<OutboxRow>(
      `SELECT id, aggregate_id, event_name, payload, created_at, attempts, next_attempt_at FROM ${table}
       WHERE published_at IS NULL AND NOT dead ORDER BY created_at, id LIMIT $1 FOR UPDATE SKIP LOCKED`,
      [BATCH],
    );
    return rows.map((r) => ({
      env: {
        id: r.id,
        module,
        name: r.event_name,
        aggregateId: r.aggregate_id,
        payload: r.payload,
        occurredAt: r.created_at,
      },
      attempts: r.attempts,
      notBefore: r.next_attempt_at,
    }));
  }

  /** Marks a delivered event published, or schedules its retry. */
  private async record(tx: PoolClient, table: string, row: PendingRow, failure?: Error) {
    const now = this.deps.clock.now();
    try {
      if (!failure) {
        await tx.query(
          `UPDATE ${table} SET published_at = $2, attempts = attempts + 1 WHERE id = $1`,
          [row.env.id, now],
        );
        return;
      }
      const attempts = row.attempts + 1;
      const backoff = Math.min(2 ** Math.min(attempts, 9) * 1000, MAX_BACKOFF_MS);
      this.deps.log.warn(
        { event: row.env.name, id: row.env.id, attempt: attempts, err: failure },
        'event delivery failed',
      );
      await tx.query(
        `UPDATE ${table} SET attempts = $2, next_attempt_at = $3, last_error = $4, dead = $5 WHERE id = $1`,
        [
          row.env.id,
          attempts,
          new Date(now.getTime() + backoff),
          failure.message,
          attempts >= MAX_ATTEMPTS,
        ],
      );
    } catch (cause) {
      throw new Error(`record delivery of ${row.env.id}`, { cause });
    }
  }
}
