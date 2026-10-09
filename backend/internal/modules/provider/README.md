# provider

Provider enrolment profile (personal info, services, service area, emergency contact, code of conduct), online presence and nearby search.

## Contract (`contract/service.go`, `ProviderService`)

- `GetProvider`
- `IsAvailable`
- `FindNearby`
- `ForceOffline`
- `Enrolment`, `MarkStepDone`, `MarkSubmitted` (verification reports document steps)
- `SearchProviders` (admin console list and record, ADR-0026)

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

Migrations: `backend/migrations/provider/`.
