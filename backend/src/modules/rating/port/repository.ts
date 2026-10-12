import { type DomainEvent } from '../../../platform/events/domain-event';
import { type Aggregate } from '../domain/aggregate';
import { type Review, type Reviewable, type ReviewRole } from '../domain/review';

/** A keyset position over (created_at, id); `limit` includes the look-ahead row. */
export interface Page {
  readonly before?: { readonly createdAt: Date; readonly id: string };
  readonly limit: number;
}

/** Stores reviewable bookings, reviews and aggregates. */
export interface RatingRepository {
  /** Opens a booking for review; adding it twice is a no-op. */
  addReviewable(b: Reviewable): Promise<void>;
  /** The completed booking; `rating.not_allowed` when there is none. */
  reviewable(bookingId: string): Promise<Reviewable>;
  /**
   * Stores the review, updates the subject's aggregate and writes the event built from
   * the new aggregate in one transaction. A second review of a booking by the same
   * author is `rating.already_reviewed`.
   */
  submit(r: Review, event: (a: Aggregate) => DomainEvent): Promise<Aggregate>;
  /** Aggregates of the given subjects of a role; unrated subjects are missing. */
  aggregates(role: ReviewRole, ids: readonly string[]): Promise<Map<string, Aggregate>>;
  /** Reviews of a subject written by a role, newest first. */
  reviews(subjectId: string, authorRole: ReviewRole, page: Page): Promise<Review[]>;
  /** Whether the author already reviewed the booking. */
  hasReviewed(bookingId: string, authorId: string): Promise<boolean>;
}

/** Injection token for the {@link RatingRepository}. */
export const RATING_REPOSITORY = Symbol('RatingRepository');
