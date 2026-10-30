# Booking area — overview

Bookings and their state machine (PRD §5, docs/guides/booking-states.md): discovery with the fixed
price, requests with every snapshot copied in, acceptance, start codes, extras, completion,
cancellation, the timeout sweep, earnings and the admin bookings monitor.

Code: `PAO.Core/Areas/Booking/`; contracts: `PAO.Lib/Areas/Booking/`. Back to the [area index](../README.md).

## Services

| Service | Role |
|---|---|
| `IBookingSharedService` | The only way other areas reach Booking (`Services/Shared/`). |
| `BookingSharedService` | Its implementation. |
| `BookingStates` | the state table, tabs, who may cancel, when contacts are shared, line pricing, start codes (CSPRNG) |
| `BookingTransitions` | the moves (accept, reject, time out, cancel, advance, start, propose, decide, complete) with `Stamp` and `CodeLimits` |
| `BookingAccess` | loads and changes bookings for one party (others' bookings are not found) and fills the fields every event carries; `Side` |
| `BookingPricing` | bookable services, prices from one catalog read, the launch area, both sides' eligibility |
| `BookingPeers` | Catalog, Customer, Identity, Merchant, Verification, Media, Admin, Rating and Billing, resolved on first use; `EnsureCanAccept` is the one place Billing's due limit is checked before an accept (ADR-0035 §3) |
| `BookingSides` | what each side sees: the provider gets the exact address and either side the other's phone only after acceptance; support sees all |
| `BookingPaging` | keyset pages over (time, id) with one look-ahead row |
| `EarningsCalendar` | Asia/Dhaka days, Saturday weeks and months (P-08) |
| `BookingSubscriptions` | erasure on `identity.AccountDeleted` (see [events](events.md)) |

## Shared contract

| Method | Contract |
|---|---|
| `GetBooking` | Returns a booking with its parties and snapshots, or throws `booking.not_found`. |
| `CountActiveJobs` | Returns how many accepted-but-unfinished jobs the merchant has; the MVP allows one active ASAP job at a time (PRD §5). |
| `GetMerchantStats` | Returns completed jobs and recent merchant cancellations, for search cards and quality thresholds (D13). |
| `ListRecentBookings` | Returns a party's latest bookings for admin detail pages. |

Mapping: `BookingMappingProfile`, `BookingRecordProfile`. Job: `BookingExpiryJob` ([jobs](../../Operations/jobs.md)).

## Billing seams (P17 task 5)

- Accept: `AcceptBookingHandler` calls `BookingPeers.EnsureCanAccept` before the transition;
  while no `IBillingSharedService` is registered there is nothing to check.
- Completion: `booking.BookingCompleted` carries the merchant (`providerId`) and the final
  `totalPaisa`, which is what Billing debits its commission from (ADR-0035 §2).
