# admin

Platform settings, complaints (customer and provider reports), the dashboard read model and admin-user and role management screens (credentials live in identity).

## Contract (`contract/service.go`, `AdminService`)

- `GetSettings`
- `CountVerifiedComplaints`

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
- `/v1/admin/admin-users*`
- `/v1/admin/roles*`
- `/v1/customer/bookings/{id}/reports`
- `/v1/provider/jobs/{id}/reports`

Migrations: `backend/migrations/admin/`.
