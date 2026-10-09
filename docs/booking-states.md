# Booking states

Source: PRD §5 ("6 main states, 2 exits"), D8, D12. This table is the test matrix for the
booking state machine (P07): every listed transition must succeed when its guard holds,
and every pair **not** listed must be rejected with `BOOKING_INVALID_TRANSITION`.

## States

| State | Meaning | Terminal |
|---|---|---|
| `requested` | Customer asked one provider; waiting for a reply until `accept_deadline` | no |
| `accepted` | Provider accepted; contact details and exact address are now shared | no |
| `on_the_way` | Provider set off | no |
| `arrived` | Provider is at the address, waiting for the start code | no |
| `in_progress` | Correct start code entered; extras may be proposed | no |
| `completed` | Job done and cash confirmed | yes |
| `rejected` | Provider declined; customer returns to the provider list (C47) | yes |
| `timed_out` | Nobody answered before the deadline; customer returns to the list (C13b) | yes |
| `cancelled` | Customer or provider cancelled before the job started | yes |

## Transitions

| # | From | To | Who | Guard | Event |
|---|---|---|---|---|---|
| 1 | `requested` | `accepted` | provider | before `accept_deadline`; provider can receive bookings for the service; for an ASAP booking the provider has no other active job (PRD §5 "one active job"); per-booking Redis lock so only one accept wins | `BookingAccepted` |
| 2 | `requested` | `rejected` | provider | before `accept_deadline`; reason given | `BookingRejected` |
| 3 | `requested` | `timed_out` | system | `now ≥ accept_deadline` (job `booking.expire_request`) | `BookingTimedOut` |
| 4 | `requested` | `cancelled` | customer | reason given; free (D8) | `BookingCancelled` (`AfterAcceptance=false`) |
| 5 | `accepted` | `on_the_way` | provider | — | `ProviderOnTheWay` |
| 6 | `on_the_way` | `arrived` | provider | — | `ProviderArrived` |
| 7 | `arrived` | `in_progress` | provider | start code matches; fewer than 5 wrong attempts, not inside the 10-minute lockout | `BookingStarted` |
| 8 | `in_progress` | `completed` | provider | `cashReceived = true`; no pending extras proposal | `BookingCompleted` |
| 9 | `accepted`, `on_the_way`, `arrived` | `cancelled` | customer | reason given; free until the start code is entered (D8) | `BookingCancelled` (`AfterAcceptance=true`) |
| 10 | `accepted`, `on_the_way`, `arrived` | `cancelled` | provider | reason given; counted in quality metrics (PRD §6.4, D13) | `BookingCancelled` (`AfterAcceptance=true`) |

## Actions that keep the state

| Action | State | Who | Guard | Event |
|---|---|---|---|---|
| Wrong start code | `arrived` | provider | increments attempts; the 5th wrong code locks entry for 10 minutes (settings) | — |
| Propose extras | `in_progress` | provider | catalog sub-services of the booked service only, no free-text prices (PRD §5); no other proposal pending | `ExtraItemsProposed` |
| Decide extras | `in_progress` | customer | a proposal is pending; approval adds its items to the total, declining discards them | `ExtraItemsDecided` |

## Notes

- Cancellation after `in_progress` is impossible for both sides (`CANCELLATION_NOT_ALLOWED`,
  screen C54); problems go through "Report a problem" instead.
- Rejected and timed-out bookings are not retried; the customer books another provider,
  which creates a new booking (PRD §5 step 6).
- The start code is a 4-digit CSPRNG value generated at acceptance and shown only to the
  customer.
- Every transition appends a timeline entry `(status, at, actor, reason)`.
