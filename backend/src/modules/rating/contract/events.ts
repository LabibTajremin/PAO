import { type DomainEvent } from '../../../platform/events/domain-event';

/** Outbox names of the rating module's events; stored, so they never change. */
export const RatingEvents = {
  ReviewSubmitted: 'rating.ReviewSubmitted',
} as const;

/**
 * Published after a review is stored, carrying the new aggregate so subscribers
 * (search ranking, quality review) need not call back.
 */
export interface ReviewSubmitted extends DomainEvent<typeof RatingEvents.ReviewSubmitted> {
  readonly reviewId: string;
  readonly bookingId: string;
  readonly authorId: string;
  readonly subjectId: string;
  readonly subjectRole: string;
  readonly stars: number;
  readonly newAverage: number;
  readonly newCount: number;
}

/** Any event the rating module publishes. */
export type RatingEvent = ReviewSubmitted;
