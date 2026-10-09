# verification

Level 1 document items and their review, levels, Level 2 sessions, document expiry and reminders, the NID block list.

## Contract (`contract/service.go`, `VerificationService`)

- `GetLevel`
- `GetLevels`
- `CanReceiveBookings`
- `GetItems`, `CountPendingReviews` (admin console)

## Events published

- `ProviderLevelChanged`
- `DocumentApproved`
- `DocumentRejected`
- `DocumentExpired`
- `DocumentExpiring`
- `Level2SessionScheduled`
- `Level2ResultRecorded`

## Events consumed

- `provider.EnrolmentStepSaved`
- `identity.AccountStatusChanged (ban → block NID)`
- `identity.AccountDeleted`

## Tables (schema `verification`)

- `items`
- `documents`
- `nid_records`
- `blocked_nids`
- `levels`
- `level2_sessions`
- `reminders_sent`
- `outbox`
- `processed_events`

## HTTP routes

- `/v1/provider/enrolment (nid, selfie, police-clearance, skill-proof, submit)`
- `/v1/provider/verification`
- `/v1/admin/verifications*`
- `/v1/admin/documents/*`
- `/v1/admin/level2-sessions*`

Migrations: `backend/migrations/verification/`.
