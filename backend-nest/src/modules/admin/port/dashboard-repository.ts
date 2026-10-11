import { type DayCount } from '../domain/dashboard';

/** The read-model counts behind the dashboard. */
export interface DashboardCounts {
  readonly providersByStatus: Record<string, number>;
  readonly providersByLevel: Record<string, number>;
  readonly openComplaints: number;
  /** Stored booking days on or after the requested date. */
  readonly days: DayCount[];
}

/** Reads the dashboard read model (A-09). */
export interface DashboardRepository {
  /** Returns the counts with booking days since `since` (YYYY-MM-DD). */
  dashboard(since: string): Promise<DashboardCounts>;
}

/** Injection token for the {@link DashboardRepository}. */
export const DASHBOARD_REPOSITORY = Symbol('DashboardRepository');
