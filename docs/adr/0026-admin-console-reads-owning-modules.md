# ADR-0026: Admin console reads the owning modules through their contracts

- Status: Accepted
- Date: 2026-10-09
- Source: docs/build/phases/P09-admin-api.md; PRD §7.3 (A-05, A-06, A-09), §9.3

## Context

The admin people screens combine data owned by provider, customer, verification,
booking, rating, audit and admin itself. Modules may not join across schemas, and the
admin module is wired before the modules that read its settings.

## Decision

- The admin module serves `/v1/admin/providers*`, `/v1/admin/customers*` and the
  dashboard. It reads each owner through its contract (`SearchProviders`,
  `SearchCustomers`, `GetItems`, `ListRecentBookings`, `ListForSubject`, …). The
  modules built after admin are supplied with `admin.Module.Connect` before serving.
- Provider and customer lists are served from each owner's table; customer keeps copies
  of phone, account status and booking count, kept current from identity and booking
  events.
- The bookings monitor (`/v1/admin/bookings*`) lives in the booking module, which owns
  the rows and the timeline.
- An active provider without Level 1 is shown as `pending` (PRD §6.4) in lists,
  filters and the dashboard.
- Status changes go through identity's `SetAccountStatus`; the response shows the new
  status at once while read models catch up from `AccountStatusChanged`.
- Face references are not stored by the MVP, so a ban blocks the phone and NID only.

## Consequences

The admin console has no tables of its own for people. New admin views add a contract
method to the owning module rather than a query in admin.
