import { Global, Module } from '@nestjs/common';
import {
  CustomerReviewsController,
  ProviderReviewsController,
} from './adapter/http/rating.controller';
import { RatingContract } from './adapter/inproc/rating-contract';
import { RatingWorker } from './adapter/inproc/worker-hooks';
import { PostgresRatingRepository } from './adapter/postgres/rating-repository';
import { Ratings } from './app/ratings';
import { SubmitReview } from './app/submit-review';
import { RATING_SERVICE } from './contract/rating-service';
import { RATING_REPOSITORY } from './port/repository';

/** Two-way reviews after completed bookings and their aggregates (C-11, P-09). */
@Global()
@Module({
  controllers: [CustomerReviewsController, ProviderReviewsController],
  providers: [
    { provide: RATING_REPOSITORY, useClass: PostgresRatingRepository },
    SubmitReview,
    Ratings,
    RatingWorker,
    { provide: RATING_SERVICE, useClass: RatingContract },
  ],
  exports: [RATING_SERVICE],
})
export class RatingModule {}
