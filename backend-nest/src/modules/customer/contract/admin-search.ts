/**
 * Filters the admin customer list (A-05). Empty or null fields do not filter;
 * `afterAt` and `afterId` continue from the last row of the previous page.
 */
export interface CustomerQuery {
  readonly id: string | null;
  readonly text: string;
  readonly status: string;
  readonly afterAt: Date | null;
  readonly afterId: string | null;
  readonly limit: number;
}

/** A customer as the admin console lists it. */
export interface CustomerRecord {
  readonly id: string;
  readonly name: string;
  readonly phone: string;
  readonly status: string;
  readonly bookings: number;
  readonly createdAt: Date;
}
