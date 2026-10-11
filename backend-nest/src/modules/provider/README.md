# provider

Provider enrolment profile (personal info, services, service area, emergency contact, code of conduct), online presence and nearby search.

Layout (ADR-0032): `contract/` is the only folder other modules may import; it holds
the service interface and its injection token, DTOs, `DomainError` reasons and event
types with their outbox names (`contract/index.ts`). Queries live in
`adapter/postgres/queries.sql`; `npm run gen` regenerates `adapter/postgres/sqlc/`.

## Contract (`contract/provider-service.ts`, `ProviderService`, token `PROVIDER_SERVICE`)

- `getProvider`
- `isAvailable`
- `findNearby`
- `forceOffline`
- `enrolment`, `markStepDone`, `markSubmitted` (verification reports document steps)
- `searchProviders` (admin console list and record, ADR-0026)

## Events published

- `EnrolmentStepSaved`
- `ProviderFlaggedForReview`
- `ProviderWentOffline`

## Events consumed

- `identity.RoleGranted`
- `identity.AccountStatusChanged`
- `identity.AccountDeleted`
- `verification.ProviderLevelChanged`
- `verification.DocumentExpired`
- `rating.ReviewSubmitted`
- `booking.BookingCompleted`
- `booking.BookingCancelled`
- `admin.ComplaintResolved`

## Tables (schema `provider`)

- `providers`
- `provider_services`
- `outbox`
- `processed_events`

## HTTP routes

- `/v1/provider/profile`
- `/v1/provider/enrolment (personal, services, area, emergency contact, code of conduct)`
- `/v1/provider/presence/*`
- `/v1/customer/providers/{id}`
- `/v1/admin/providers*`

Migrations: `backend-nest/migrations/provider/`.
