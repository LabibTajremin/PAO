# ADR-0041: Scheduled delivery as subscriptions that become bookings

- Status: Accepted
- Date: 2026-11-25
- Source: owner requirements xi and xii (06-update-2026-11.md), phase P25. The phase file asks
  for "ADR-0039", but that number went to the catalog icons (P22), so this is ADR-0041.

## Context

Homemade food (office lunch, party food), catering and the monthly bazar are delivered on a
date or on a repeating schedule. Each delivery needs its own status, its own cash payment and
its own merchant due (ADR-0035). The booking area already gives one job all of this: the
state machine, start codes, COD, the commission debit when it completes, receipts, the
partner's live job screens and the admin monitor.

## Decision

1. **Service model.** A new `scheduled_delivery` service model. Its service carries a
   `schedule` the admin edits: allowed patterns (`once`, `daily`, `weekdays`, `weekly`,
   `monthly`), delivery windows (`12:00–13:00`), the minimum lead time in hours (defaults:
   food 12, catering 48, bazar 24), the cutoff time on the day before (default `20:00`), the
   quantity unit (`meals`, `guests`, `package`) and the minimum and maximum quantity.
   Homemade food (Office lunch, Party food), Catering and Monthly Bazar use it.
2. **Subscription.** A customer orders a subscription from one merchant: service, items,
   quantity, address, window, pattern (weekdays for `weekdays` and `weekly`, a day of the
   month for `monthly`), start date and either an end date or a count, and a note. Its status
   is `requested → active ⇄ paused → finished`, or `declined` / `cancelled`. The merchant
   accepts it once; the accept checks the due limit like a booking accept (ADR-0035 §3).
3. **Dates.** The dates come from the pattern, computed in Asia/Dhaka; a `monthly` date on
   a day the month lacks falls on its last day. Dates in the admin setting `booking.delivery_holidays`
   (comma-separated ISO dates, a plain string setting) are left out. Only exceptions are stored: a date the customer
   skipped or changed, one the merchant declined, and one already made into a booking.
4. **Deliveries become bookings.** At the cutoff on the day before, a sweep turns each
   active subscription's next date into an **accepted booking** for that window, with the
   subscription's lines and the date's quantity. From there the delivery is an ordinary
   booking: the merchant goes on the way, hands over with the start code and completes;
   the customer pays cash for that delivery and the merchant's commission is debited for
   it. A delivery's status is derived: `scheduled` before the sweep, then `preparing`
   (accepted on the day), `out_for_delivery` (on the way or arrived), `delivered`, `skipped`,
   `declined` or `cancelled`.
5. **Changes.** Before a date's cutoff the customer can skip or unskip it or change its
   quantity, and the merchant can decline it. Pause, resume and cancel act on dates not yet
   made into bookings; a booking already made is cancelled through the booking rules.
6. **Reminders.** The sweep tells the merchant of tomorrow's deliveries and the customer of
   tomorrow's window, through the P18 channels.

## Consequences

- Booking owns two new tables, `booking.subscriptions` and `booking.subscription_dates`,
  and a `subscription_id` on bookings; Catalog gains `services.schedule`.
- New operations under `/v1/customer/subscriptions`, `/v1/provider/subscriptions`,
  `/v1/provider/deliveries` and `/v1/admin/subscriptions`.
- The sweep is the job `booking.materialise_deliveries`, every five minutes; a missed run
  catches up while the delivery date is still ahead.
- The start code doubles as proof of hand-over for deliveries.
