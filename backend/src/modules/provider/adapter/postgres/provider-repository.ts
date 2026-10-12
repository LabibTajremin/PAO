import { Inject, Injectable } from '@nestjs/common';
import { CLOCK, type Clock } from '../../../../platform/clock/clock';
import { DATABASE, type Database, type SqlClient } from '../../../../platform/db/database';
import { DomainError } from '../../../../platform/errors/domain-error';
import { type DomainEvent } from '../../../../platform/events/domain-event';
import { type ProviderQuery, type ProviderRecord } from '../../contract/admin-search';
import { type Provider } from '../../domain/provider';
import { ProviderReasons } from '../../domain/reasons';
import { type ProviderRepository, type RadiusCandidate } from '../../port/repository';
import { PROVIDER_OUTBOX, type ProviderOutbox } from './outbox';
import { saveArgs, toProvider } from './rows';
import {
  addService,
  candidates,
  clearServices,
  ensureProvider,
  providerByID,
  saveProfile,
  searchProviders,
} from './sqlc/queries_sql';

/** Keeps admin search text literal inside a LIKE pattern. */
function likePattern(text: string): string {
  const t = text.trim().toLowerCase();
  return t === '' ? '' : `%${t.replace(/[\\%_]/g, (c) => `\\${c}`)}%`;
}

/** The provider schema on PostGIS. */
@Injectable()
export class PostgresProviderRepository implements ProviderRepository {
  constructor(
    @Inject(DATABASE) private readonly db: Database,
    @Inject(PROVIDER_OUTBOX) private readonly outbox: ProviderOutbox,
    @Inject(CLOCK) private readonly clock: Clock,
  ) {}

  ensure(id: string, phone: string, at: Date): Promise<void> {
    return ensureProvider(this.db.pool, { id, phone, createdAt: at });
  }

  async get(id: string): Promise<Provider> {
    const row = await providerByID(this.db.pool, { id });
    if (row === null) {
      throw new DomainError(ProviderReasons.NotFound);
    }
    return toProvider(row);
  }

  save(p: Provider, events: readonly DomainEvent[] = []): Promise<void> {
    return this.db.transaction(async (tx) => {
      await saveProfile(tx, saveArgs(p, this.clock.now()));
      await clearServices(tx, { providerId: p.id });
      for (const serviceId of p.serviceIds) {
        await addService(tx, { providerId: p.id, serviceId });
      }
      await this.write(tx, p.id, events);
    });
  }

  publish(id: string, events: readonly DomainEvent[]): Promise<void> {
    return this.db.transaction((tx) => this.write(tx, id, events));
  }

  private async write(tx: SqlClient, id: string, events: readonly DomainEvent[]): Promise<void> {
    for (const e of events) {
      await this.outbox.write(tx, id, e);
    }
  }

  async candidates(ids: readonly string[], minLevel: number): Promise<RadiusCandidate[]> {
    const rows = await candidates(this.db.pool, { ids: [...ids], minLevel });
    return rows.map((c) => ({
      id: c.id,
      name: c.fullName,
      photoMediaId: c.photoMediaId,
      gender: c.gender ?? '',
      level: c.level,
      rating: c.ratingAvg,
      ratingCount: c.ratingCount,
      completedJobs: c.completedJobs,
      distanceM: 0,
      workingRadiusM: c.workingRadiusM,
    }));
  }

  async search(q: ProviderQuery): Promise<ProviderRecord[]> {
    const rows = await searchProviders(this.db.pool, {
      id: q.id,
      pattern: likePattern(q.text),
      status: q.status === '' ? null : q.status,
      level: q.level,
      flagged: q.flagged,
      beforeAt: q.afterAt,
      // The query ignores the id without a time; any uuid satisfies the parameter type.
      beforeId: q.afterId ?? '00000000-0000-0000-0000-000000000000',
      maxRows: String(q.limit),
    });
    return rows.map((r) => ({
      id: r.id,
      name: r.fullName,
      phone: r.phone,
      status: r.status,
      level: r.level,
      serviceIds: r.serviceIds,
      rating: r.ratingAvg,
      ratingCount: r.ratingCount,
      completedJobs: r.completedJobs,
      flagged: r.flaggedForReview,
      flagReason: r.flagReason,
      online: false,
      createdAt: r.createdAt,
    }));
  }
}
