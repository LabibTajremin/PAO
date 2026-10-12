import { Inject, Injectable } from '@nestjs/common';
import { CLOCK, type Clock } from '../../../platform/clock/clock';
import { DomainError } from '../../../platform/errors/domain-error';
import { ID_GENERATOR, type IdGenerator } from '../../../platform/ids/id-generator';
import { RatingEvents, type ReviewSubmitted } from '../contract/events';
import { average } from '../domain/aggregate';
import {
  newReview,
  type Review,
  type Reviewable,
  type ReviewInput,
  type ReviewRole,
  subjectRole,
} from '../domain/review';
import { RATING_REPOSITORY, type RatingRepository } from '../port/repository';

/** Two-way reviews of completed bookings, once per side (C-11, P-09). */
@Injectable()
export class SubmitReview {
  constructor(
    @Inject(RATING_REPOSITORY) private readonly repo: RatingRepository,
    @Inject(CLOCK) private readonly clock: Clock,
    @Inject(ID_GENERATOR) private readonly ids: IdGenerator,
  ) {}

  /** Makes a completed booking reviewable by both sides. */
  open(b: Reviewable): Promise<void> {
    return this.repo.addReviewable(b);
  }

  /** Records one side's review of a completed booking. */
  async review(
    author: { readonly id: string; readonly role: ReviewRole },
    bookingId: string,
    input: ReviewInput,
  ): Promise<Review> {
    const booking = await this.repo.reviewable(bookingId);
    const checked = newReview(booking, author, input);
    if (typeof checked === 'string') {
      throw new DomainError(checked);
    }
    const r: Review = {
      ...checked,
      id: this.ids.newId(),
      createdAt: this.clock.now(),
    };
    await this.repo.submit(r, (a): ReviewSubmitted => ({
      name: RatingEvents.ReviewSubmitted,
      reviewId: r.id,
      bookingId: r.bookingId,
      authorId: r.authorId,
      subjectId: r.subjectId,
      subjectRole: subjectRole(r.authorRole),
      stars: r.stars,
      newAverage: average(a),
      newCount: a.count,
    }));
    return r;
  }
}
