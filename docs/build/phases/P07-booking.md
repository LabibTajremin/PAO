# P07 — Discovery & booking

**Goal:** the core flow of PRD §5 works end to end through the API, with every rule
enforced on the server.

**Read first:** PRD §5 (all), features C-05–C-10, C-12, P-05–P-08; `docs/booking-states.md`.

## Tasks

1. **Domain state machine** — states and transitions exactly as `booking-states.md`.
   Pure functions, no I/O; each transition returns events.
2. **Create booking** — idempotency key required (PRD §9.6); snapshots copied in: price
   version + amounts per item, service name, provider display name (PRD §9.3 rule 4);
   ASAP or scheduled slot; address ID and note; provider must pass `CanReceiveBookings`
   and `IsAvailable`; customer may not have another `Requested` booking with the same
   provider. Schedules `booking.expire_request` (D12).
3. **Respond** — provider accept (Redis lock per booking; one-active-ASAP-job rule),
   reject with reason; timeout job. On reject/timeout the customer is returned to the
   provider list (C13b/C47).
4. **Progress** — on the way, arrived, start (4-digit code generated at acceptance with a
   CSPRNG, shown only to the customer; 5 wrong attempts lock for 10 min), complete with
   "cash received" confirmation and final bill.
5. **Extra items** — provider proposes catalog sub-services only (no free-text prices,
   PRD §5); customer approves or declines; totals recalculated from snapshots.
6. **Cancel** — customer until start code entered, with reason (C-10); provider after
   acceptance with reason (counted for quality); both publish `BookingCancelled`.
7. **Read models** — customer bookings upcoming/past, provider jobs upcoming/past, booking
   detail with timeline, receipt data, provider earnings summaries (daily/weekly/monthly,
   Asia/Dhaka boundaries) and by-job list.
8. **Privacy** — exact address and customer phone visible to the provider only after
   acceptance; provider phone visible to the customer only after acceptance (PRD §5, step 6).
9. **Discovery endpoint** — `nearby providers` for a sub-service + quantity + address,
   with the fixed price summary (C10), using `provider.FindNearby`.

## Tests

- Unit: full transition matrix (every allowed and forbidden pair), totals with extras,
  start-code attempts and lockout, cancellation guard, earnings period boundaries.
- Integration: concurrent accepts (only one wins), idempotent create (same key → same
  booking), timeout job fires with the fake clock, provider with an active ASAP job cannot
  accept another, address hidden before acceptance.
- Performance smoke in `test/perf`: nearby search p95 < 300 ms with 2,000 seeded online
  providers.

## Definition of done

The whole happy path and every exit (reject, timeout, cancel) pass through the HTTP API.
`./pao ci` green; PR merged.
