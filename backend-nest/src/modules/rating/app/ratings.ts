import { Inject, Injectable } from '@nestjs/common';
import { type Aggregate, UNRATED } from '../domain/aggregate';
import { type Review, ReviewRole } from '../domain/review';
import { type Page, RATING_REPOSITORY, type RatingRepository } from '../port/repository';

/** Reads aggregates and review lists. */
@Injectable()
export class Ratings {
  constructor(@Inject(RATING_REPOSITORY) private readonly repo: RatingRepository) {}

  /** Aggregates of subjects of a role; unrated subjects are missing. */
  summaries(role: ReviewRole, ids: readonly string[]): Promise<Map<string, Aggregate>> {
    return this.repo.aggregates(role, ids);
  }

  /** One subject's aggregate, zero when unrated. */
  async summary(role: ReviewRole, id: string): Promise<Aggregate> {
    return (await this.repo.aggregates(role, [id])).get(id) ?? UNRATED;
  }

  /** Customers' reviews of a provider, newest first. */
  providerReviews(providerId: string, page: Page): Promise<Review[]> {
    return this.repo.reviews(providerId, ReviewRole.Customer, page);
  }

  /** Whether the author already reviewed the booking. */
  hasReviewed(bookingId: string, authorId: string): Promise<boolean> {
    return this.repo.hasReviewed(bookingId, authorId);
  }
}
