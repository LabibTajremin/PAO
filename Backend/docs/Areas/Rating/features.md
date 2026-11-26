# Rating area — features

One entry per feature folder (`Features/<Feature>/Commands|Queries/`): the use case, its
request, validator and handler. Overview: [overview.md](overview.md).

| Feature | Use case | Kind | Notes |
|---|---|---|---|
| `Reviews` | `SubmitReview` | command | once per side (REVIEW_ALREADY_SUBMITTED), only on completed bookings (REVIEW_NOT_ALLOWED); `rating.ReviewSubmitted` carries the new aggregate |
| `Reviews` | `OpenReviewable`, `EraseReviewAuthor` | command | sent by the subscribers; both idempotent |
| `Reviews` | `ListProviderReviews`, `GetMyRating` | query | customers' reviews of a provider, newest first; the breakdown keyed "1".."5" |
