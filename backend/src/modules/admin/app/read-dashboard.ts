import { Inject, Injectable } from '@nestjs/common';
import { CLOCK, type Clock, DHAKA_OFFSET_MS } from '../../../platform/clock/clock';
import { addDays, type Dashboard, DASHBOARD_DAYS, fillDays } from '../domain/dashboard';
import { type CachedValue, CONSOLE, type Console } from '../port/console';
import { DASHBOARD_REPOSITORY, type DashboardRepository } from '../port/dashboard-repository';

/** The dashboard as cached; JSON keeps the time as text. */
export type CachedDashboard = Omit<Dashboard, 'generatedAt'> & { generatedAt: string };

/** Injection token for the dashboard's {@link CachedValue}. */
export const DASHBOARD_CACHE = Symbol('DashboardCache');

/** Today's calendar date in Asia/Dhaka (04-decisions E8), YYYY-MM-DD. */
export function dhakaDate(now: Date): string {
  return new Date(now.getTime() + DHAKA_OFFSET_MS).toISOString().slice(0, 10);
}

/** The admin home numbers (A-09). */
@Injectable()
export class ReadDashboard {
  constructor(
    @Inject(DASHBOARD_REPOSITORY) private readonly repo: DashboardRepository,
    @Inject(CONSOLE) private readonly console: Console,
    @Inject(DASHBOARD_CACHE) private readonly cache: CachedValue<CachedDashboard>,
    @Inject(CLOCK) private readonly clock: Clock,
  ) {}

  /** Returns the numbers, cached for a minute: a minute-old count is fine. */
  async execute(): Promise<Dashboard> {
    const cached = await this.cache.read();
    if (cached !== undefined) {
      return { ...cached, generatedAt: new Date(cached.generatedAt) };
    }
    const today = dhakaDate(this.clock.now());
    const counts = await this.repo.dashboard(addDays(today, 1 - DASHBOARD_DAYS));
    const pendingVerifications = await this.console.verification().countPendingReviews();
    const { days, completionRate } = fillDays(today, counts.days);
    const generatedAt = this.clock.now();
    const d: Dashboard = {
      providersByStatus: counts.providersByStatus,
      providersByLevel: counts.providersByLevel,
      bookingsPerDay: days,
      completionRate,
      openComplaints: counts.openComplaints,
      pendingVerifications,
      generatedAt,
    };
    await this.cache.write({ ...d, generatedAt: generatedAt.toISOString() });
    return d;
  }
}
