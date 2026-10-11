/** How many days of bookings the dashboard charts (A-09). */
export const DASHBOARD_DAYS = 30;

const DAY_MS = 24 * 60 * 60 * 1000;

/** One day's bookings; `date` is a calendar date, YYYY-MM-DD. */
export interface DayCount {
  readonly date: string;
  readonly total: number;
  readonly completed: number;
}

/** The admin home screen's numbers (A-09). */
export interface Dashboard {
  readonly providersByStatus: Record<string, number>;
  readonly providersByLevel: Record<string, number>;
  readonly bookingsPerDay: readonly DayCount[];
  readonly completionRate: number;
  readonly openComplaints: number;
  readonly pendingVerifications: number;
  readonly generatedAt: Date;
}

/** Returns the calendar date `days` after `date` (both YYYY-MM-DD). */
export function addDays(date: string, days: number): string {
  return new Date(Date.parse(`${date}T00:00:00Z`) + days * DAY_MS).toISOString().slice(0, 10);
}

/**
 * Returns one entry per day of the window ending `today`, so charts show gaps as zeros,
 * and the share of requested bookings that were completed, to two decimals.
 */
export function fillDays(
  today: string,
  stored: readonly DayCount[],
): { days: DayCount[]; completionRate: number } {
  const byDay = new Map(stored.map((d) => [d.date, d]));
  const days: DayCount[] = [];
  let total = 0;
  let completed = 0;
  for (let i = DASHBOARD_DAYS - 1; i >= 0; i--) {
    const date = addDays(today, -i);
    const d = byDay.get(date) ?? { date, total: 0, completed: 0 };
    total += d.total;
    completed += d.completed;
    days.push({ date, total: d.total, completed: d.completed });
  }
  const completionRate = total === 0 ? 0 : Math.round((completed / total) * 100) / 100;
  return { days, completionRate };
}
