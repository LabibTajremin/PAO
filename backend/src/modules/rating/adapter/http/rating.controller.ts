import { Body, Controller, Get, Param, Post, Query } from '@nestjs/common';
import { decodeCursor, pageSize } from '../../../../platform/http/cursor';
import { MapErrors } from '../../../../platform/http/map-errors';
import { type components, type operations } from '../../../../platform/http/openapi.gen';
import { RequirePermission } from '../../../../platform/http/permissions';
import { type Principal } from '../../../../platform/http/principal';
import { CurrentPrincipal } from '../../../../platform/http/request-decorators';
import { Ratings } from '../../app/ratings';
import { SubmitReview } from '../../app/submit-review';
import { ReviewRole } from '../../domain/review';
import { breakdown, ratingErrors, reviewPage, reviewView } from './views';

type Schemas = components['schemas'];
type PageQuery = NonNullable<operations['listMyReviews']['parameters']['query']>;

function input(body: Schemas['ReviewInput']) {
  return { stars: body.stars, tags: body.tags ?? [], comment: body.comment ?? '' };
}

/** Reads one page of a provider's reviews. */
async function providerReviews(ratings: Ratings, providerId: string, q: PageQuery) {
  const cursor = decodeCursor(q.cursor);
  const size = pageSize(q.limit);
  const rows = await ratings.providerReviews(providerId, {
    before: cursor && { createdAt: new Date(cursor.createdAt), id: cursor.id },
    limit: size + 1,
  });
  return reviewPage(rows, size);
}

/** The customer's side: rating the provider and reading a provider's reviews (C-11, C42). */
@Controller('v1/customer')
@MapErrors(ratingErrors)
export class CustomerReviewsController {
  constructor(
    private readonly reviews: SubmitReview,
    private readonly ratings: Ratings,
  ) {}

  @Post('bookings/:bookingId/review')
  @RequirePermission('review:create')
  async review(
    @CurrentPrincipal() me: Principal,
    @Param('bookingId') bookingId: string,
    @Body() body: Schemas['ReviewInput'],
  ): Promise<Schemas['Review']> {
    const author = { id: me.accountId, role: ReviewRole.Customer };
    return reviewView(await this.reviews.review(author, bookingId, input(body)));
  }

  @Get('providers/:providerId/reviews')
  @RequirePermission('provider:browse')
  list(
    @Param('providerId') providerId: string,
    @Query() q: PageQuery,
  ): Promise<Schemas['ReviewList']> {
    return providerReviews(this.ratings, providerId, q);
  }
}

/** The provider's side: rating the customer, their reviews and breakdown (P-09, M30). */
@Controller('v1/provider')
@MapErrors(ratingErrors)
export class ProviderReviewsController {
  constructor(
    private readonly reviews: SubmitReview,
    private readonly ratings: Ratings,
  ) {}

  @Post('jobs/:bookingId/review')
  @RequirePermission('review:create')
  async review(
    @CurrentPrincipal() me: Principal,
    @Param('bookingId') bookingId: string,
    @Body() body: Schemas['ReviewInput'],
  ): Promise<Schemas['Review']> {
    const author = { id: me.accountId, role: ReviewRole.Provider };
    return reviewView(await this.reviews.review(author, bookingId, input(body)));
  }

  @Get('reviews')
  @RequirePermission('provider:manage:own')
  list(@CurrentPrincipal() me: Principal, @Query() q: PageQuery): Promise<Schemas['ReviewList']> {
    return providerReviews(this.ratings, me.accountId, q);
  }

  @Get('rating')
  @RequirePermission('provider:manage:own')
  async rating(@CurrentPrincipal() me: Principal): Promise<Schemas['RatingBreakdown']> {
    return breakdown(await this.ratings.summary(ReviewRole.Provider, me.accountId));
  }
}
