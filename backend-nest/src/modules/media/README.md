# media

Direct-to-storage uploads with presigned URLs, upload confirmation, 5-minute signed view URLs and orphan purging.

Layout (ADR-0032): `contract/` is the only folder other modules may import; it holds
the service interface and its injection token, DTOs, `DomainError` reasons and event
types with their outbox names (`contract/index.ts`). Queries live in
`adapter/postgres/queries.sql`; `npm run gen` regenerates `adapter/postgres/sqlc/`.

## Contract (`contract/media-service.ts`, `MediaService`, token `MEDIA_SERVICE`)

- `createUploadUrl`
- `confirmUpload`
- `getObject`
- `markAttached`
- `getViewUrl`
- `delete`

## Events published

None.

## Events consumed

None. (The Go README listed `identity.AccountDeleted`, but no media subscriber exists.)

## Tables (schema `media`)

- `objects`
- `outbox`
- `processed_events`

## HTTP routes

- `/v1/customer/uploads*`
- `/v1/provider/uploads*`
- `/v1/admin/documents/{mediaId}/view-url`

## Jobs

- `media.purge_orphans`, daily at 03:30 Dhaka: deletes uploads never attached within 24 h.

Viewing a sensitive document (verification purposes) writes a `media.document_viewed`
entry through the audit contract (`AUDIT_SERVICE`) before the URL is handed out.

Migrations: `backend-nest/migrations/media/`.
