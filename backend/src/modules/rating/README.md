# rating

Two-way reviews after completed bookings and incrementally updated aggregates.

Layout (ADR-0032): `contract/` is the only folder other modules may import; it holds
the service interface and its injection token, DTOs, `DomainError` reasons and event
types with their outbox names (`contract/index.ts`). Queries live in
`adapter/postgres/queries.sql`; `npm run gen` regenerates `adapter/postgres/sqlc/`.

## Contract (`contract/rating-service.ts`, `RatingService`, token `RATING_SERVICE`)

- `getProviderRating`
- `getProviderRatings`
- `getCustomerRating`
- `hasReviewed` (booking views show `reviewedByMe`)

## Events published

- `ReviewSubmitted`

## Events consumed

- `booking.BookingCompleted` (opens the booking for review; redelivery is a no-op)

## Tables (schema `rating`)

- `reviewable_bookings`
- `reviews`
- `aggregates`
- `outbox`
- `processed_events`

## HTTP routes

- `/v1/customer/bookings/{id}/review`
- `/v1/provider/jobs/{id}/review`
- `/v1/customer/providers/{id}/reviews`
- `/v1/provider/reviews`
- `/v1/provider/rating`

## Layout

- `domain/` — eligibility and content rules (`newReview`), aggregates and averages.
- `app/` — `SubmitReview` (open a booking, review it once per side), `Ratings` (reads).
- `adapter/postgres/` — reviews, the aggregate upsert and the outbox in one transaction.
- `adapter/http/` — the five routes, views and the error map.
- `adapter/inproc/` — the contract and the BookingCompleted subscriber.

Migrations: `backend/migrations/rating/`.
