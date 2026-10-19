# Booking area — endpoints

One entry per controller and its operations, with the authorisation attribute that matches
each operation's `x-permission` (see [authorisation](../../Architecture/authorization.md)).
Errors map through `BookingErrorMap`.

| Controller | Operations | Attribute |
|---|---|---|
| `CustomerBookingsController` | `POST /v1/customer/bookings` (201, Idempotency-Key), `GET …`, `GET …/{bookingId}`, `…/start-code`, `POST …/cancel`, `…/extras/decision`, `GET …/receipt` | `[Customer(Permission = "booking:create" / "booking:read:own" / "booking:cancel:own" / "booking:update:own")]` |
| `ProviderJobsController` | `GET /v1/provider/jobs`, `GET …/{bookingId}`, `POST …/accept`, `…/reject`, `…/on-the-way`, `…/arrived`, `…/start`, `…/extras`, `…/complete`, `…/cancel`, `GET …/receipt` | `[Merchant(Permission = "job:read:own" / "job:respond" / "job:progress")]` |
| `DiscoveryControllers` | the file holding the error map and the three controllers below | |
| `NearbyController` | `GET /v1/customer/providers/nearby` | `[Customer(Permission = "provider:browse")]` |
| `AdminBookingsController` | `GET /v1/admin/bookings`, `GET …/{bookingId}` | `[Admin(Permission = "booking:read:any")]` |
| `EarningsController` | `GET /v1/provider/earnings/summary`, `…/jobs` | `[Merchant(Permission = "earnings:read:own")]` |

Reviews and reports on bookings belong to Rating and Admin.
