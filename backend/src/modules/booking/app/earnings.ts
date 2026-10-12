import { Injectable } from '@nestjs/common';
import { DomainError } from '../../../platform/errors/domain-error';
import { addDays, dayStart, days, dhakaDay, isoDate, month, period } from '../domain/earnings';
import { BookingReasons } from '../domain/reasons';
import { type DayTotal, type EarningsJob, type Page } from '../port/repository';
import { BookingAccess } from './access';

/** A provider's totals for a calendar period (P-08). */
export interface Earnings {
  readonly from: Date;
  readonly to: Date;
  readonly total: number;
  readonly jobs: number;
  readonly days: DayTotal[];
}

/** Provider earnings per Asia/Dhaka day. */
@Injectable()
export class ProviderEarnings {
  constructor(private readonly access: BookingAccess) {}

  /** Totals completed jobs per day over the period containing `day` (default today). */
  async summary(provider: string, kind: string, day: Date | null): Promise<Earnings> {
    const p = period(kind, day ?? dhakaDay(this.access.clock.now()));
    if (p === undefined) {
      throw new DomainError(BookingReasons.Invalid);
    }
    const range = { from: dayStart(p.from), until: dayStart(addDays(p.to, 1)) };
    const rows = await this.access.repo.earningsByDay(provider, range);
    const byDay = new Map(rows.map((r) => [isoDate(r.day), r]));
    const all = days(p.from, p.to).map((d) => ({
      day: d,
      total: byDay.get(isoDate(d))?.total ?? 0,
      jobs: byDay.get(isoDate(d))?.jobs ?? 0,
    }));
    return {
      from: p.from,
      to: p.to,
      total: all.reduce((s, d) => s + d.total, 0),
      jobs: all.reduce((s, d) => s + d.jobs, 0),
      days: all,
    };
  }

  /**
   * Completed jobs between two Dhaka dates (inclusive); open ends default to the
   * current month.
   */
  jobs(
    provider: string,
    between: { from: Date | null; to: Date | null },
    p: Page,
  ): Promise<EarningsJob[]> {
    const current = month(dhakaDay(this.access.clock.now()));
    const from = between.from ?? current.from;
    const to = between.to ?? current.to;
    const range = { from: dayStart(from), until: dayStart(addDays(to, 1)) };
    return this.access.repo.earningsJobs(provider, range, p);
  }
}
