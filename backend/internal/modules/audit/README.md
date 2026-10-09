# audit

The append-only audit trail: who did what, when, to what and why (PRD §6.4).

## Contract (`contract/service.go`, `AuditService`)

- `Record`
- `ListForSubject`

## Events published

None.

## Events consumed

- `identity.AccountStatusChanged`
- `verification.DocumentApproved`
- `verification.DocumentRejected`
- `verification.ProviderLevelChanged`
- `catalog.PriceChanged`
- `admin.SettingChanged`
- `admin.ComplaintResolved`
- `booking.BookingCancelled`

## Tables (schema `audit`)

- `entries (UPDATE/DELETE/TRUNCATE rejected by triggers)`
- `processed_events`

## HTTP routes

- `/v1/admin/audit`

Migrations: `backend/migrations/audit/`.
