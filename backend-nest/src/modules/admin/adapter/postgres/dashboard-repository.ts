import { Inject, Injectable } from '@nestjs/common';
import { DATABASE, type Database } from '../../../../platform/db/database';
import { type DashboardCounts, type DashboardRepository } from '../../port/dashboard-repository';
import {
  bookingsSince,
  countOpenComplaints,
  providersByLevel,
  providersByStatus,
} from './sqlc/queries_sql';

/**
 * The Date node-postgres reads and writes for a `date` column: midnight in the process
 * time zone, which keeps the calendar day whatever that zone is.
 */
export function sqlDate(day: string): Date {
  const [y, m, d] = day.split('-').map(Number);
  return new Date(y ?? 0, (m ?? 1) - 1, d ?? 1);
}

/** The calendar day (YYYY-MM-DD) of a `date` column value. */
export function dayOf(d: Date): string {
  const pad = (n: number) => String(n).padStart(2, '0');
  return `${String(d.getFullYear())}-${pad(d.getMonth() + 1)}-${pad(d.getDate())}`;
}

/** The dashboard read model of the admin schema (A-09). */
@Injectable()
export class PostgresDashboardRepository implements DashboardRepository {
  constructor(@Inject(DATABASE) private readonly db: Database) {}

  async dashboard(since: string): Promise<DashboardCounts> {
    const q = this.db.pool;
    const [statuses, levels, days, open] = await Promise.all([
      providersByStatus(q),
      providersByLevel(q),
      bookingsSince(q, { day: sqlDate(since) }),
      countOpenComplaints(q),
    ]);
    return {
      providersByStatus: Object.fromEntries(statuses.map((s) => [s.status, Number(s.n)])),
      providersByLevel: Object.fromEntries(levels.map((l) => [String(l.level), Number(l.n)])),
      openComplaints: Number(open?.count),
      days: days.map((d) => ({ date: dayOf(d.day), total: d.requested, completed: d.completed })),
    };
  }
}
