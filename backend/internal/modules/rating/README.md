# rating

Two-way reviews after completed bookings and incrementally updated aggregates.

## Contract (`contract/service.go`, `RatingService`)

- `GetProviderRating`
- `GetProviderRatings`
- `GetCustomerRating`

## Events published

- `ReviewSubmitted`

## Events consumed

- `booking.BookingCompleted`
- `identity.AccountDeleted`

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

Migrations: `backend/migrations/rating/`.
