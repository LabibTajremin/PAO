# Rating area — overview

Two-way reviews after completed bookings (C-11, P-09) and the running aggregates of merchants
and customers.

Code: `PAO.Core/Areas/Rating/`; contracts: `PAO.Lib/Areas/Rating/`. Back to the [area index](../README.md).

## Services

| Service | Role |
|---|---|
| `IRatingSharedService` | The only way other areas reach Rating (`Services/Shared/`). |
| `RatingSharedService` | Its implementation. |
| `RatingRules` | who may review (that side of the completed booking), 1–5 stars, six distinct tags, 500 characters; first names only |
| `RatingSubscriptions` | opens completed bookings for review, erases deleted authors (see [events](events.md)) |

## Shared contract

| Method | Contract |
|---|---|
| `GetMerchantRating` | Returns the merchant's aggregate (zero values when unrated). |
| `GetMerchantRatings` | Returns aggregates for many merchants, keyed by merchant id, in one query. |
| `GetCustomerRating` | Returns the aggregate merchants gave a customer (M16). |
| `HasReviewed` | Reports whether the author already reviewed the booking. |

Mapping: `RatingMappingProfile`.
