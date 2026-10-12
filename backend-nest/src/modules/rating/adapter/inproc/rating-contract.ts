import { Injectable } from '@nestjs/common';
import { Ratings } from '../../app/ratings';
import { type RatingSummary } from '../../contract/dto';
import { type RatingService } from '../../contract/rating-service';
import { type Aggregate, average } from '../../domain/aggregate';
import { ReviewRole } from '../../domain/review';

function summary(a: Aggregate): RatingSummary {
  return { average: average(a), count: a.count, distribution: a.distribution };
}

/** The rating contract for other modules in the process. */
@Injectable()
export class RatingContract implements RatingService {
  constructor(private readonly ratings: Ratings) {}

  async getProviderRating(providerId: string): Promise<RatingSummary> {
    return summary(await this.ratings.summary(ReviewRole.Provider, providerId));
  }

  async getProviderRatings(providerIds: readonly string[]): Promise<Map<string, RatingSummary>> {
    const all = await this.ratings.summaries(ReviewRole.Provider, providerIds);
    return new Map([...all].map(([id, a]) => [id, summary(a)]));
  }

  async getCustomerRating(customerId: string): Promise<RatingSummary> {
    return summary(await this.ratings.summary(ReviewRole.Customer, customerId));
  }

  hasReviewed(bookingId: string, authorId: string): Promise<boolean> {
    return this.ratings.hasReviewed(bookingId, authorId);
  }
}
