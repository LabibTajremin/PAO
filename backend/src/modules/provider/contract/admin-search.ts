/**
 * Filters the admin provider list (A-05). Empty or null fields do not filter;
 * `afterAt` and `afterId` continue from the last row of the previous page.
 */
export interface ProviderQuery {
  readonly id: string | null;
  readonly text: string;
  readonly status: string;
  readonly level: number | null;
  readonly flagged: boolean | null;
  readonly afterAt: Date | null;
  readonly afterId: string | null;
  readonly limit: number;
}

/**
 * A provider as the admin console lists it. `status` is the account status, except
 * that an active provider without Level 1 is "pending" (PRD §6.4).
 */
export interface ProviderRecord {
  readonly id: string;
  readonly name: string;
  readonly phone: string;
  readonly status: string;
  readonly level: number;
  readonly serviceIds: readonly string[];
  readonly rating: number;
  readonly ratingCount: number;
  readonly completedJobs: number;
  readonly flagged: boolean;
  readonly flagReason: string;
  readonly online: boolean;
  readonly createdAt: Date;
}
