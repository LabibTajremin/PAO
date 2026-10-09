# media

Direct-to-storage uploads with presigned URLs, upload confirmation, 5-minute signed view URLs and orphan purging.

## Contract (`contract/service.go`, `MediaService`)

- `CreateUploadURL`
- `ConfirmUpload`
- `GetObject`
- `MarkAttached`
- `GetViewURL`
- `Delete`

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

Migrations: `backend/migrations/media/`.
