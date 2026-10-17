/** A rating aggregate; zero values when unrated. */
export interface RatingSummary {
  readonly average: number;
  readonly count: number;
  /** Review counts for one to five stars, in that order. */
  readonly distribution: readonly [number, number, number, number, number];
}
