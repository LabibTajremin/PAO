# audit

The append-only audit trail: who did what, when, to what and why (PRD §6.4).

Layout (ADR-0032): `contract/` is the only folder other modules may import; it holds
the service interface and its injection token, DTOs, `DomainError` reasons and event
types with their outbox names (`contract/index.ts`). Queries live in
`adapter/postgres/queries.sql`; `npm run gen` regenerates `adapter/postgres/sqlc/`.

`AuditLog` (`app/audit-log.ts`) appends and lists entries; `app/event-entries.ts` maps
each audited event to its entry, and `adapter/worker/audit-subscribers.ts` records them
in the worker with the event id, so a redelivered event adds nothing. The table rejects
UPDATE, DELETE and TRUNCATE.

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
- `verification.Level2ResultRecorded`
- `verification.DocumentExpired`

## Tables (schema `audit`)

- `entries (UPDATE/DELETE/TRUNCATE rejected by triggers)`
- `processed_events`

## HTTP routes

- `/v1/admin/audit`

Migrations: `backend-nest/migrations/audit/`.
