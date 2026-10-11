# audit

The append-only audit trail: who did what, when, to what and why (PRD §6.4).

Layout (ADR-0032): `contract/` is the only folder other modules may import; it holds
the service interface and its injection token, DTOs, `DomainError` reasons and event
types with their outbox names (`contract/index.ts`). Queries live in
`adapter/postgres/queries.sql`; `npm run gen` regenerates `adapter/postgres/sqlc/`.

## Contract (`contract/audit-service.ts`, `AuditService`, token `AUDIT_SERVICE`)

- `record`
- `listForSubject`

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

Migrations: `backend-nest/migrations/audit/`.
