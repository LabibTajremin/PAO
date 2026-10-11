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

- `identity.AccountDeleted`

## Tables (schema `media`)

- `objects`
- `outbox`
- `processed_events`

## HTTP routes

- `/v1/customer/uploads*`
- `/v1/provider/uploads*`

Migrations: `backend-nest/migrations/media/`.
