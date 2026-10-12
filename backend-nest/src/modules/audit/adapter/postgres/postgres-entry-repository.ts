import { Inject, Injectable } from '@nestjs/common';
import { DATABASE, type Database } from '../../../../platform/db/database';
import { type Entry, type Filter } from '../../domain/entry';
import { type EntryRepository, type Page } from '../../port/entry-repository';
import * as q from './sqlc/queries_sql';

type Json = Readonly<Record<string, unknown>> | null;

function filterArgs(f: Filter) {
  return {
    actorId: f.actorId ?? null,
    action: f.action ?? null,
    subjectType: f.subjectType ?? null,
    subjectId: f.subjectId ?? null,
    fromAt: f.from ?? null,
    toAt: f.to ?? null,
  };
}

/**
 * Writes and reads `audit.entries`. It has no update or delete, and the table's triggers
 * reject them anyway.
 */
@Injectable()
export class PostgresEntryRepository implements EntryRepository {
  constructor(@Inject(DATABASE) private readonly db: Database) {}

  async append(e: Entry): Promise<void> {
    await q.appendEntry(this.db.pool, {
      ...e,
      before: e.before === null ? null : JSON.stringify(e.before),
      after: e.after === null ? null : JSON.stringify(e.after),
    });
  }

  async list(f: Filter, page: Page): Promise<Entry[]> {
    const rows = await q.list(this.db.pool, {
      ...filterArgs(f),
      cursorAt: page.after?.at ?? null,
      cursorId: page.after?.id ?? null,
      pageSize: String(page.limit),
    });
    return rows.map((r) => ({
      ...r,
      before: r.before as Json,
      after: r.after as Json,
      eventId: null,
    }));
  }
}
