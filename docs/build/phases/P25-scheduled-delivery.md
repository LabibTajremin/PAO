# P25 — Scheduled delivery services (homemade food, catering, monthly bazar)

**Goal:** customers can order homemade food for the office or a party, catering and monthly
bazar for one date or on a repeating schedule; merchants see and fulfil each delivery.

**Read first:** `06-update-2026-11.md` items xi, xii; ADR-0035 (COD, merchant dues, the
catering and monthly-bazar categories); PRD booking sections; booking state machine (P07).

## Product rules

- New category **Homemade food** with services **Office lunch** (daily/weekday tiffin) and
  **Party food** (one date, headcount). Catering and Monthly bazar move onto the same model.
- Service model `scheduled_delivery`, configured per service by the admin: allowed
  patterns (one-time, daily, selected weekdays, weekly, monthly on a day), delivery windows
  (e.g. 12:00–13:00), minimum lead time (food 12 h, catering 48 h, bazar 24 h by default),
  order cutoff for the next day (e.g. 20:00), quantity unit (meals, guests, package), min/max.
- An order is a **subscription** (start date, end date or count, address, window, quantity,
  notes) that produces **deliveries**. Each delivery has its own status (scheduled → preparing
  → out for delivery → delivered / skipped / cancelled), its own COD payment and its own merchant
  due (ADR-0035 per delivery).
- The customer can skip or change one delivery before its cutoff, pause, resume or cancel the
  rest. The merchant accepts the subscription once, can decline single dates before cutoff, and
  sees a calendar of upcoming deliveries.

## Tasks

1. ADR-0039 for the model above; OpenAPI changes first.
2. Backend: tables, a background job that materialises deliveries D-1 at the cutoff, reminders
   (customer evening before, merchant at cutoff), notifications through the P18 channels,
   cancellation and refund rules consistent with existing COD rules. No N+1; indexed by date.
3. Customer app: schedule picker (pattern, days, window, dates, quantity), subscription detail
   with upcoming deliveries, skip/pause/cancel, per-delivery receipt.
4. Partner app: subscriptions inbox, daily delivery list, calendar, status updates.
5. Admin: service schedule settings; subscriptions and deliveries in the bookings monitor.
6. Seed the new category and services with icons from P22.
7. Tests: unit for schedule expansion (month ends, Fridays, holidays list), integration for the
   job and state changes, e2e journey: order weekday lunch for two weeks → skip a day →
   deliveries arrive → COD per delivery.

## Definition of done

The journey above passes end to end against `./pao up`. `./pao ci` green.
