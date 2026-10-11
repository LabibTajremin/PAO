# booking

The booking lifecycle and state machine (docs/booking-states.md), snapshots, start code, extra items, cancellation, timeouts, receipts, earnings and nearby discovery.

Layout (ADR-0032): `contract/` is the only folder other modules may import; it holds
the service interface and its injection token, DTOs, `DomainError` reasons and event
types with their outbox names (`contract/index.ts`). Queries live in
`adapter/postgres/queries.sql`; `npm run gen` regenerates `adapter/postgres/sqlc/`.

## Contract (`contract/booking-service.ts`, `BookingService`, token `BOOKING_SERVICE`)

- `getBooking`
- `countActiveJobs`
- `getProviderStats`
- `listRecentBookings`

## Events published

- `BookingRequested`
- `BookingAccepted`
- `BookingRejected`
- `BookingTimedOut`
- `ProviderOnTheWay`
- `ProviderArrived`
- `BookingStarted`
- `ExtraItemsProposed`
- `ExtraItemsDecided`
- `BookingCompleted`
- `BookingCancelled`

## Events consumed

- `identity.AccountDeleted (anonymise snapshots)`

## Tables (schema `booking`)

- `bookings`
- `booking_items`
- `extras_proposals`
- `timeline`
- `outbox`
- `processed_events`

## HTTP routes

- `/v1/customer/bookings*`
- `/v1/customer/providers/nearby`
- `/v1/provider/jobs*`
- `/v1/provider/earnings/*`
- `/v1/admin/bookings*`

Migrations: `backend-nest/migrations/booking/`.
