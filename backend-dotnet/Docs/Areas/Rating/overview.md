# Rating area — overview

Reviews after completed bookings and the rating aggregates of merchants and customers.

Code: `PAO.Core/Areas/Rating/`; contracts: `PAO.Lib/Areas/Rating/`. Back to the [area index](../README.md).

## Services

| Service | Role |
|---|---|
| `IRatingSharedService` | The only way other areas reach Rating (`Services/Shared/`). Implemented when the use cases are ported. |

## Shared contract

| Method | Contract |
|---|---|
| `GetMerchantRating` | Returns the merchant's aggregate (zero values when unrated). |
| `GetMerchantRatings` | Returns aggregates for many merchants, keyed by merchant id, for search ranking (one query, no N+1). |
| `GetCustomerRating` | Returns the aggregate merchants gave a customer (M16). |
| `HasReviewed` | Reports whether the author already reviewed the booking. |
