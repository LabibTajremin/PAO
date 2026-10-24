# Booking area — events

Events are written to the area's outbox in the same transaction as the change and relayed at
least once ([events and jobs](../../Architecture/events-and-jobs.md)). Every payload carries
`bookingId`, `number`, `customerId`, `providerId`, `serviceId` and `at`, field for field as
NestJS wrote them; Notification, Audit, Merchant, Customer, Rating and Admin subscribe.

| Published event | Extra fields |
|---|---|
| `booking.BookingRequested` | `acceptDeadline`, `scheduled`, `totalPaisa` |
| `booking.BookingAccepted` | |
| `booking.BookingRejected` | `reason` |
| `booking.BookingTimedOut` | |
| `booking.ProviderOnTheWay` | |
| `booking.ProviderArrived` | |
| `booking.BookingStarted` | |
| `booking.ExtraItemsProposed` | `proposalId`, `addedPaisa`, `newTotalPaisa` |
| `booking.ExtraItemsDecided` | `proposalId`, `approved` |
| `booking.BookingCompleted` | `totalPaisa`, `customerName`, `providerName`, `serviceName` — Billing's commission source |
| `booking.BookingCancelled` | `by`, `reason`, `afterAcceptance` |

Consumed by `BookingSubscriptions` (handler `booking`): `identity.AccountDeleted`.
