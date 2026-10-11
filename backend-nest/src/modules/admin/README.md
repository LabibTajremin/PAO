# admin

Platform settings, complaints (customer and provider reports), the dashboard read model and admin-user and role management are served by identity.

Layout (ADR-0032): `contract/` is the only folder other modules may import; it holds
the service interface and its injection token, DTOs, `DomainError` reasons and event
types with their outbox names (`contract/index.ts`). Queries live in
`adapter/postgres/queries.sql`; `npm run gen` regenerates `adapter/postgres/sqlc/`.

## Contract (`contract/admin-service.ts`, `AdminService`, token `ADMIN_SERVICE`)

- `getSettings`
- `countVerifiedComplaints`

## Events published

- `ComplaintCreated`
- `ComplaintResolved`
- `SettingChanged`

## Events consumed

- `booking.BookingRequested`
- `booking.BookingCompleted`
- `verification.ProviderLevelChanged`
- `identity.AccountStatusChanged`
- `identity.RoleGranted`

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
- `/v1/customer/bookings/{id}/reports`
- `/v1/provider/jobs/{id}/reports`

Migrations: `backend-nest/migrations/admin/`.
