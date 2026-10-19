# Booking area — features

One entry per feature folder (`Features/<Feature>/Commands|Queries/`): the use case, its
request, validator and handler. Overview: [overview.md](overview.md).

| Feature | Use case | Kind | Notes |
|---|---|---|---|
| `Requests` | `CreateBooking` | request with its own transaction | snapshots, price lines, idempotency key (a repeat returns the stored booking), DUPLICATE_BOOKING_REQUEST, PROVIDER_UNAVAILABLE, OUTSIDE_SERVICE_AREA, PROFILE_REQUIRED |
| `Respond` | `AcceptBooking`, `RejectBooking`, `CancelBooking` | command | provider and row locks; ACCEPT_DEADLINE_PASSED, ACTIVE_JOB_EXISTS, CANCELLATION_NOT_ALLOWED; reasons stored as `reason: note` |
| `Respond` | `ExpireDueRequests` | request | the `booking.expire_requests` sweep; each request times out in its own transaction |
| `Progress` | `AdvanceJob`, `ProposeExtras`, `DecideExtras`, `CompleteJob` | command | on the way, arrived, catalog extras, cash confirmation (D4) |
| `Progress` | `StartJob` | request with its own transaction | a wrong code is saved before START_CODE_INVALID is reported, so the lockout survives retries |
| `Read` | `GetBooking`, `GetStartCode`, `GetReceipt`, `ListBookings` | query | per side, `reviewedByMe` from Rating for completed bookings; tabs |
| `Monitor` | `MonitorBookings`, `GetSupportBooking` | query | admin filters by status, service, area and Dhaka dates (A-06) |
| `Discovery` | `FindNearbyProviders` | query | the fixed price and verified, online providers (C10) |
| `Earnings` | `GetEarningsSummary`, `ListEarningsJobs` | query | every day of the period; jobs default to this month |
| `Erasure` | `EraseBookingSnapshots` | command | blanks a deleted account's details (PRD §11) |
