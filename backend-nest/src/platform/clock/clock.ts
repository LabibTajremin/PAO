/** The injectable time source used instead of `new Date()` (01-conventions.md §4). */
export interface Clock {
  now(): Date;
}

/** Injection token for the {@link Clock}. */
export const CLOCK = Symbol('Clock');

/** The real clock. */
export class SystemClock implements Clock {
  now(): Date {
    return new Date();
  }
}

/** Asia/Dhaka is UTC+6 with no daylight saving; calendar boundaries use it (04-decisions E8). */
export const DHAKA_OFFSET_MS = 6 * 60 * 60 * 1000;
