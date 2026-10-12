import { Controller, Get, Query } from '@nestjs/common';
import { MapErrors } from '../../../../platform/http/map-errors';
import { type operations } from '../../../../platform/http/openapi.gen';
import { RequirePermission } from '../../../../platform/http/permissions';
import { type Principal } from '../../../../platform/http/principal';
import { CurrentPrincipal } from '../../../../platform/http/request-decorators';
import { bookingNumber } from '../../app/access';
import { ProviderEarnings } from '../../app/earnings';
import { isoDate } from '../../domain/earnings';
import { bookingErrors } from './error-map';
import { nextCursor, page, type Schemas } from './views';

type SummaryQuery = operations['getEarningsSummary']['parameters']['query'];
type JobsQuery = NonNullable<operations['listEarningsJobs']['parameters']['query']>;

/** A YYYY-MM-DD query date as a calendar day. */
export function calendarDay(d: string | undefined): Date | null {
  return d === undefined ? null : new Date(`${d}T00:00:00Z`);
}

/** The provider's earnings per Asia/Dhaka day (P-08). */
@Controller('v1/provider/earnings')
@MapErrors(bookingErrors)
@RequirePermission('earnings:read:own')
export class EarningsController {
  constructor(private readonly earnings: ProviderEarnings) {}

  @Get('summary')
  async summary(
    @CurrentPrincipal() me: Principal,
    @Query() q: SummaryQuery,
  ): Promise<Schemas['EarningsSummary']> {
    const e = await this.earnings.summary(me.accountId, q.period, calendarDay(q.date));
    return {
      period: q.period,
      from: isoDate(e.from),
      to: isoDate(e.to),
      total: e.total,
      jobs: e.jobs,
      buckets: e.days.map((d) => ({ date: isoDate(d.day), jobs: d.jobs, total: d.total })),
    };
  }

  @Get('jobs')
  async jobs(
    @CurrentPrincipal() me: Principal,
    @Query() q: JobsQuery,
  ): Promise<Schemas['EarningsJobList']> {
    const { size, page: p } = page(q.cursor, q.limit);
    const between = { from: calendarDay(q.from), to: calendarDay(q.to) };
    const rows = await this.earnings.jobs(me.accountId, between, p);
    return {
      items: rows.slice(0, size).map((r) => ({
        bookingId: r.id,
        number: bookingNumber(r.number),
        completedAt: r.completedAt.toISOString(),
        serviceName: r.serviceName,
        total: r.totalPaisa,
      })),
      nextCursor: nextCursor(rows, size, (r) => r.completedAt),
    };
  }
}
