// Calendar days are Asia/Dhaka dates held as UTC midnights, so date arithmetic never
// meets a time zone; Dhaka is UTC+6 all year (04-decisions E8).

const DAY_MS = 86_400_000;
const DHAKA_OFFSET_MS = 6 * 3_600_000;

/** A reporting period of the earnings screen (P-08). */
export type Period = 'day' | 'week' | 'month';

/** The Dhaka calendar date of an instant. */
export function dhakaDay(instant: Date): Date {
  return new Date(Math.floor((instant.getTime() + DHAKA_OFFSET_MS) / DAY_MS) * DAY_MS);
}

/** The instant a Dhaka calendar date begins. */
export function dayStart(day: Date): Date {
  return new Date(day.getTime() - DHAKA_OFFSET_MS);
}

/** The calendar date `n` days after `day`. */
export function addDays(day: Date, n: number): Date {
  return new Date(day.getTime() + n * DAY_MS);
}

/** The date as YYYY-MM-DD. */
export function isoDate(day: Date): string {
  return day.toISOString().slice(0, 10);
}

/**
 * Returns the first and last calendar day (inclusive) of the period containing `day`.
 * Weeks start on Saturday, the first working day after the Bangladeshi Friday weekend.
 */
export function period(kind: string, day: Date): { from: Date; to: Date } | undefined {
  switch (kind) {
    case 'day':
      return { from: day, to: day };
    case 'week': {
      const from = addDays(day, -((day.getUTCDay() + 1) % 7));
      return { from, to: addDays(from, 6) };
    }
    case 'month': {
      const [y, m] = [day.getUTCFullYear(), day.getUTCMonth()];
      return { from: new Date(Date.UTC(y, m, 1)), to: new Date(Date.UTC(y, m + 1, 0)) };
    }
  }
  return undefined;
}

/** Every date from `from` to `to` inclusive. */
export function days(from: Date, to: Date): Date[] {
  const out: Date[] = [];
  for (let d = from; d <= to; d = addDays(d, 1)) {
    out.push(d);
  }
  return out;
}
