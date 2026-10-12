/** Review counts for one to five stars, in that order. */
export type Distribution = readonly [number, number, number, number, number];

/** An incrementally updated rating summary. */
export interface Aggregate {
  readonly count: number;
  readonly sum: number;
  readonly distribution: Distribution;
}

/** The aggregate of someone nobody has reviewed yet. */
export const UNRATED: Aggregate = { count: 0, sum: 0, distribution: [0, 0, 0, 0, 0] };

/** The mean rating rounded to one decimal, 0 when unrated. */
export function average(a: Aggregate): number {
  return a.count === 0 ? 0 : Math.floor((a.sum / a.count) * 10 + 0.5) / 10;
}
