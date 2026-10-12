# verification

Level 1 document items and their review, levels, Level 2 sessions, document expiry and reminders, the NID block list.

Layout (ADR-0032): `contract/` is the only folder other modules may import; it holds
the service interface and its injection token, DTOs, `DomainError` reasons and event
types with their outbox names (`contract/index.ts`). Queries live in
`adapter/postgres/queries.sql`; `npm run gen` regenerates `adapter/postgres/sqlc/`.

## Contract (`contract/verification-service.ts`, `VerificationService`, token `VERIFICATION_SERVICE`)

- `getLevel`
- `getLevels`
- `canReceiveBookings`
- `getItems`, `countPendingReviews` (admin console)

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
- `identity.AccountStatusChanged` (suspend or ban → blocked; ban → NID on the block list)

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
- `/v1/admin/level2-sessions*`

## Jobs and seams

- `verification.expire_documents`, daily 02:00 Asia/Dhaka; `verification.expiry_reminders`,
  daily 09:00 (30, 7 and 1 days before expiry, each sent once).
- `DOCUMENT_EXPIRY` (test hooks): `POST /__test/verification/expire?at=…` runs the sweep.

## Notes

- `change` runs under the provider's row lock (`SELECT … FOR UPDATE` on `levels`) and
  recomputes the level, publishing `ProviderLevelChanged` in the same transaction.
- NID numbers are stored with the platform `DataCipher` (AES-GCM) plus a keyed hash for
  the block list; they are decrypted only for the review screen.
- Police clearance issue dates compare against the Dhaka calendar date.

Migrations: `backend/migrations/verification/`.
