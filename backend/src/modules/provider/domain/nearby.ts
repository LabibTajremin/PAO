/** A provider found near a customer. */
export interface Candidate {
  readonly id: string;
  readonly name: string;
  readonly photoMediaId: string | null;
  readonly gender: string;
  readonly level: number;
  readonly rating: number;
  readonly ratingCount: number;
  readonly completedJobs: number;
  readonly distanceM: number;
}

/**
 * Orders candidates Level 2 first, then by distance or rating (PRD §5); ties fall back
 * to distance. The sort is stable, so equal candidates keep their order.
 */
export function rank<C extends Candidate>(list: readonly C[], byRating: boolean): C[] {
  return [...list].sort((a, b) => {
    const proA = a.level >= 2;
    if (proA !== b.level >= 2) {
      return proA ? -1 : 1;
    }
    if (byRating && a.rating !== b.rating) {
      return b.rating - a.rating;
    }
    return a.distanceM - b.distanceM;
  });
}
