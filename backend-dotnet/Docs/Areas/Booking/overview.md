# Booking area — overview

Bookings and their state machine (PRD §5): requests, acceptance, start codes, extras, completion, cancellation and timeouts.

Code: `PAO.Core/Areas/Booking/`; contracts: `PAO.Lib/Areas/Booking/`. Back to the [area index](../README.md).

## Services

| Service | Role |
|---|---|
| `IBookingSharedService` | The only way other areas reach Booking (`Services/Shared/`). Implemented when the use cases are ported. |

## Shared contract

| Method | Contract |
|---|---|
| `GetBooking` | Returns a booking with its parties and snapshots, or throws `booking.not_found`. |
| `CountActiveJobs` | Returns how many accepted-but-unfinished jobs the merchant has; the MVP allows one active ASAP job at a time (PRD §5). |
| `GetMerchantStats` | Returns completed jobs and recent merchant cancellations, for search cards and quality thresholds (D13). |
| `ListRecentBookings` | Returns a party's latest bookings for admin detail pages. |
