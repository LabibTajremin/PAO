import { Inject, Injectable } from '@nestjs/common';
import { CLOCK, type Clock } from '../../../../platform/clock/clock';
import { DATABASE, type Database } from '../../../../platform/db/database';
import { DomainError } from '../../../../platform/errors/domain-error';
import { type DomainEvent } from '../../../../platform/events/domain-event';
import { type Session } from '../../domain/level2';
import { VerificationReasons } from '../../domain/reasons';
import { newState, type State } from '../../domain/state';
import {
  type Change,
  type ExpiringItem,
  type Page,
  type QueueFilter,
  type QueueRow,
  type SessionFilter,
  type VerificationRepository,
} from '../../port/repository';
import { VERIFICATION_OUTBOX, type VerificationOutbox } from './outbox';
import {
  blockNID,
  countPendingReviews,
  ensureLevel,
  expiredBy,
  expiringBetween,
  levelByProvider,
  levels,
  listSessions,
  lockLevel,
  nIDBlocked,
  queue,
  recordReminderQuery,
  sessionByID,
} from './sqlc/queries_sql';
import { loadState, saveState, toSession } from './state-rows';

// The queries ignore the id without a time; any uuid satisfies the parameter type.
const NO_ID = '00000000-0000-0000-0000-000000000000';

/** The verification schema. */
@Injectable()
export class PostgresVerificationRepository implements VerificationRepository {
  constructor(
    @Inject(DATABASE) private readonly db: Database,
    @Inject(VERIFICATION_OUTBOX) private readonly outbox: VerificationOutbox,
    @Inject(CLOCK) private readonly clock: Clock,
  ) {}

  async load(id: string): Promise<State> {
    const lvl = await levelByProvider(this.db.pool, { providerId: id });
    return lvl === null ? newState(id) : loadState(this.db.pool, id, lvl);
  }

  change(id: string, fn: Change): Promise<State> {
    return this.db.transaction(async (tx) => {
      await ensureLevel(tx, { providerId: id });
      const lvl = await lockLevel(tx, { providerId: id });
      const st = await loadState(tx, id, lvl ?? newState(id));
      const events = await fn(st);
      await saveState(tx, st, this.clock.now());
      for (const e of events) {
        await this.outbox.write(tx, id, e);
      }
      return st;
    });
  }

  async levels(ids: readonly string[]): Promise<Map<string, number>> {
    const rows = await levels(this.db.pool, { ids: [...ids] });
    return new Map(rows.map((r) => [r.providerId, r.level]));
  }

  async countPendingReviews(): Promise<number> {
    return Number((await countPendingReviews(this.db.pool))?.count);
  }

  queue(f: QueueFilter, p: Page): Promise<QueueRow[]> {
    return queue(this.db.pool, {
      serviceId: f.serviceId,
      itemType: f.itemType,
      afterAt: p.at,
      afterId: p.id ?? NO_ID,
      maxRows: String(p.limit),
    });
  }

  async sessions(f: SessionFilter, p: Page): Promise<Session[]> {
    const rows = await listSessions(this.db.pool, {
      providerId: f.providerId,
      status: f.status,
      beforeAt: p.at,
      beforeId: p.id ?? NO_ID,
      maxRows: String(p.limit),
    });
    return rows.map(toSession);
  }

  async session(id: string): Promise<Session> {
    const row = await sessionByID(this.db.pool, { id });
    if (row === null) {
      throw new DomainError(VerificationReasons.NotFound);
    }
    return toSession(row);
  }

  async expiredBy(t: Date): Promise<string[]> {
    const rows = await expiredBy(this.db.pool, { expiresAt: t });
    return rows.map((r) => r.providerId);
  }

  expiringBetween(from: Date, to: Date): Promise<ExpiringItem[]> {
    return expiringBetween(this.db.pool, { afterAt: from, untilAt: to });
  }

  remindOnce(it: ExpiringItem, daysBefore: number, e: DomainEvent): Promise<boolean> {
    return this.db.transaction(async (tx) => {
      const values = [it.providerId, it.itemType, it.expiresAt, daysBefore, this.clock.now()];
      const sent = (await tx.query(recordReminderQuery, values)).rowCount === 1;
      if (sent) {
        await this.outbox.write(tx, it.providerId, e);
      }
      return sent;
    });
  }

  async nidBlocked(hash: string): Promise<boolean> {
    return (await nIDBlocked(this.db.pool, { nidHash: hash }))?.exists === true;
  }

  blockNid(id: string, reason: string): Promise<void> {
    return blockNID(this.db.pool, { providerId: id, reason });
  }
}
