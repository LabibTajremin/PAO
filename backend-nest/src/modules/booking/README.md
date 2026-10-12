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

None. (The Go module listed `identity.AccountDeleted` but never subscribed; the port
keeps that behaviour.)

## Jobs

- `booking.expire_requests` every 15 s: requests past their accept deadline time out (D12).

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

## Layout

- `domain/`: the state machine (`states.ts`, `transitions.ts`), the aggregate and lines
  (`booking.ts`), Dhaka earnings periods (`earnings.ts`). Rules return a refusal reason;
  use cases throw it as a `DomainError`.
- `app/`: create (with `eligibility.ts`, `pricing.ts`), respond/expire/cancel, progress and
  extras, reads, earnings, nearby search; `access.ts` hides other people's bookings as
  not found and stamps event parties.
- `adapter/postgres/`: `change` takes the booking row lock and the provider's advisory
  lock, so concurrent accepts and the one-active-ASAP-job rule are decided one at a time.
- `adapter/http/`: privacy lives in `views.ts` — the provider sees the exact address, and
  either side the other's phone, only after acceptance (PRD §5, §11).

Migrations: `backend-nest/migrations/booking/`.
