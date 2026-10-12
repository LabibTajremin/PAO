/**
 * The admin-editable platform rules with the defaults from docs/build/04-decisions.md.
 * Durations are milliseconds.
 */
export interface Settings {
  /** The provider's time to respond to an ASAP request (D12). */
  readonly acceptTimeoutAsapMs: number;
  /** The provider's time to respond to a scheduled request (D12). */
  readonly acceptTimeoutScheduledMs: number;
  /** Applies to services without their own radius (D5). */
  readonly defaultSearchRadiusM: number;
  /** Providers rated below the floor after `ratingMinJobs` jobs are flagged (D13). */
  readonly ratingFloor: number;
  readonly ratingMinJobs: number;
  /** Flags providers who cancel too often (D13). */
  readonly maxProviderCancellations30d: number;
  /** Wrong start codes allowed before the lockout (P07). */
  readonly startCodeMaxAttempts: number;
  readonly startCodeLockoutMs: number;
  /** How long a police clearance certificate counts from its issue date. */
  readonly policeClearanceValidityMs: number;
  /** The wait before retrying a failed Level 2 session. */
  readonly level2CoolingOffMs: number;
  /** How long documents are kept after account closure (D14). */
  readonly documentRetentionMs: number;
  /** The launch area polygon (D5); empty means everywhere. */
  readonly serviceAreaGeoJson: string;
}
