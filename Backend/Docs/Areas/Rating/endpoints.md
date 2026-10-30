# Rating area — endpoints

One entry per controller and its operations, with the authorisation attribute that matches
each operation's `x-permission` (see [authorisation](../../Architecture/authorization.md)).
Errors map through `RatingErrorMap`.

| Controller | Operations | Attribute |
|---|---|---|
| `RatingControllers` | the file holding the error map and the two controllers below | |
| `CustomerReviewsController` | `POST /v1/customer/bookings/{bookingId}/review` (201); `GET /v1/customer/providers/{providerId}/reviews` | `[AllUserType(Permission = "review:create")]`; `[Customer(Permission = "provider:browse")]` |
| `ProviderReviewsController` | `POST /v1/provider/jobs/{bookingId}/review` (201); `GET /v1/provider/reviews`, `GET /v1/provider/rating` | `[AllUserType(Permission = "review:create")]`; `[Merchant(Permission = "provider:manage:own")]` |
