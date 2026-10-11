import { type RatingSummary } from './dto';

/** What other modules may ask of the rating module (PRD §9.3 rule 1). */
export interface RatingService {
  /** Returns the provider's aggregate (zero values when unrated). */
  getProviderRating(providerId: string): Promise<RatingSummary>;
  /** Returns aggregates for many providers, keyed by provider id, for search ranking. */
  getProviderRatings(providerIds: readonly string[]): Promise<Map<string, RatingSummary>>;
  /** Returns the aggregate providers gave a customer (M16). */
  getCustomerRating(customerId: string): Promise<RatingSummary>;
  /**
   * Reports whether the author already reviewed the booking, so booking views can stop
   * offering a second review.
   */
  hasReviewed(bookingId: string, authorId: string): Promise<boolean>;
}

/** Injection token for the {@link RatingService}. */
export const RATING_SERVICE = Symbol('RatingService');
