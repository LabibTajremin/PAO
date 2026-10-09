# booking

The booking lifecycle and state machine (docs/booking-states.md), snapshots, start code, extra items, cancellation, timeouts, receipts, earnings and nearby discovery.

## Contract (`contract/service.go`, `BookingService`)

- `GetBooking`
- `CountActiveJobs`
- `GetProviderStats`
- `ListRecentBookings`

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

Migrations: `backend/migrations/booking/`.
