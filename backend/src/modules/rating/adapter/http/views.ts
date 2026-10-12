import { ApiError } from '../../../../platform/http/api-error';
import { encodeCursor } from '../../../../platform/http/cursor';
import { type ErrorMap } from '../../../../platform/http/map-errors';
import { type components } from '../../../../platform/http/openapi.gen';
import { type Aggregate, average } from '../../domain/aggregate';
import { RatingReasons, type Review } from '../../domain/review';

type Schemas = components['schemas'];

/** Rating reasons as API errors, equal to the Go handler's map. */
export const ratingErrors: ErrorMap = {
  [RatingReasons.NotAllowed]: new ApiError(
    409,
    'REVIEW_NOT_ALLOWED',
    'You can review only your own completed bookings.',
  ),
  [RatingReasons.AlreadyReviewed]: new ApiError(
    409,
    'REVIEW_ALREADY_SUBMITTED',
    'You already reviewed this booking.',
  ),
  [RatingReasons.Invalid]: new ApiError(
    422,
    'VALIDATION_FAILED',
    'Check the review and try again.',
  ),
};

/** A review as the apps show it; an empty comment is left out. */
export function reviewView(r: Review): Schemas['Review'] {
  return {
    id: r.id,
    bookingId: r.bookingId,
    stars: r.stars,
    authorName: r.authorName,
    createdAt: r.createdAt.toISOString(),
    serviceName: { en: r.serviceName.en, bn: r.serviceName.bn },
    tags: r.tags as Schemas['ReviewTag'][],
    ...(r.comment === '' ? {} : { comment: r.comment }),
  };
}

/** One page of reviews; `rows` holds one look-ahead row when another page follows. */
export function reviewPage(rows: readonly Review[], size: number): Schemas['ReviewList'] {
  const items = rows.slice(0, size);
  const last = items.at(-1);
  return {
    items: items.map(reviewView),
    ...(rows.length > size && last ? { nextCursor: encodeCursor(last) } : {}),
  };
}

/** An aggregate with its distribution keyed "1" to "5". */
export function breakdown(a: Aggregate): Schemas['RatingBreakdown'] {
  const distribution = Object.fromEntries(a.distribution.map((n, i) => [String(i + 1), n]));
  return { average: average(a), count: a.count, distribution };
}
