import { Inject, Injectable } from '@nestjs/common';
import { DATABASE, type Database } from '../../../../platform/db/database';
import { type Closures } from '../../port/closures';
import * as sql from './sqlc/queries_sql';

/** `verification.closed_accounts` and the purge of a provider's records. */
@Injectable()
export class PostgresClosures implements Closures {
  constructor(@Inject(DATABASE) private readonly db: Database) {}

  record(providerId: string, closedAt: Date): Promise<void> {
    return sql.recordClosure(this.db.pool, { providerId, closedAt });
  }

  async closedBefore(cutoff: Date): Promise<string[]> {
    const rows = await sql.closedBefore(this.db.pool, { closedAt: cutoff });
    return rows.map((r) => r.providerId);
  }

  async level2Photos(providerId: string): Promise<string[]> {
    return (await sql.level2Photos(this.db.pool, { providerId })).map((r) => r.mediaId);
  }

  purge(providerId: string): Promise<void> {
    const args = { providerId };
    return this.db.transaction(async (tx) => {
      await sql.purgeItems(tx, args);
      await sql.purgeDocuments(tx, args);
      await sql.purgeNid(tx, args);
      await sql.purgeLevel2Sessions(tx, args);
      await sql.purgeReminders(tx, args);
      await sql.purgeLevel(tx, args);
      await sql.purgeClosure(tx, args);
    });
  }
}
