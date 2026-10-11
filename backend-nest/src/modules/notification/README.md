# notification

Push (FCM), SMS and in-app inbox delivery with Bangla and English templates for every booking and verification event.

Layout (ADR-0032): `contract/` is the only folder other modules may import; it holds
the service interface and its injection token, DTOs, `DomainError` reasons and event
types with their outbox names (`contract/index.ts`). Queries live in
`adapter/postgres/queries.sql`; `npm run gen` regenerates `adapter/postgres/sqlc/`.

## Contract (`contract/notification-service.ts`, `NotificationService`, token `NOTIFICATION_SERVICE`)

- `send`

## Events published

None.

## Events consumed

- `every booking.* event`
- `verification.DocumentRejected`
- `verification.DocumentExpired`
- `verification.DocumentExpiring`
- `verification.ProviderLevelChanged`
- `verification.Level2SessionScheduled`
- `admin.ComplaintResolved`
- `customer.CustomerProfileSaved`
- `identity.AccountDeleted`

## Tables (schema `notification`)

- `notifications`
- `device_tokens`
- `recipients`
- `processed_events`

## HTTP routes

- `/v1/customer/notifications*`
- `/v1/provider/notifications*`
- `/v1/customer/device-token`
- `/v1/provider/device-token`

Migrations: `backend-nest/migrations/notification/`.
