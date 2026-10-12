# admin

Platform settings, complaints (customer and provider reports), the dashboard read model
and the admin people console (ADR-0026). Admin users and roles are served by identity;
the bookings monitor (`/v1/admin/bookings*`) by booking.

Layout (ADR-0032): `contract/` is the only folder other modules may import. `domain/`
holds the pure rules (setting types, complaint transitions, dashboard days), `app/` one
use case per file with the `DomainError` reasons in `app/errors.ts`, `port/` the
interfaces the use cases need. Queries live in `adapter/postgres/queries.sql`;
`npm run gen` regenerates `adapter/postgres/sqlc/`.

## Contract (`contract/admin-service.ts`, `AdminService`, token `ADMIN_SERVICE`)

- `getSettings` — typed values, cached in Redis (`cache:settings`, 10 min) and dropped
  on every edit; a missing or damaged row falls back to the seeded default.
- `countVerifiedComplaints`

## Other modules read through their contracts

Booking, verification, provider, customer, rating, audit, catalog, identity and media
are resolved on first use (`adapter/peers`, the platform `LazyContract`), because
customer, provider, verification and booking read admin settings themselves.

## Events published

- `ComplaintCreated`
- `ComplaintResolved`
- `SettingChanged`

## Events consumed (dashboard read model, `adapter/postgres/stats-subscribers.ts`)

- `identity.AccountCreated`, `identity.AccountStatusChanged`, `identity.AccountDeleted`
- `verification.ProviderLevelChanged`
- `booking.BookingRequested`, `booking.BookingCompleted` (counted on the Asia/Dhaka day)

The dashboard itself is cached for a minute (`cache:dashboard`).

## Tables (schema `admin`)

- `settings`
- `complaints`
- `complaint_comments`
- `stats_bookings_daily`
- `stats_providers`
- `outbox`
- `processed_events`

## HTTP routes

- `/v1/admin/dashboard`
- `/v1/admin/settings*`
- `/v1/admin/complaints*`
- `/v1/admin/providers*`, `/v1/admin/customers*`
- `/v1/customer/bookings/{id}/reports`
- `/v1/provider/jobs/{id}/reports`

Migrations: `backend/migrations/admin/`.
