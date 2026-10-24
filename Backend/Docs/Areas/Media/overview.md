# Media area — overview

Uploads to private buckets through presigned URLs, upload confirmation, signed view URLs and the orphan purge.

Code: `PAO.Core/Areas/Media/`; contracts: `PAO.Lib/Areas/Media/`. Back to the [area index](../README.md).

## Services

| Service | Role |
|---|---|
| `IMediaSharedService` | The only way other areas reach Media (`Services/Shared/`); implemented by `MediaSharedService` (uploads as the admin uploader; both refusals become `media.upload_invalid`). |
| `MediaRules` | Purposes, types and sizes (documents JPEG/PNG/PDF up to 5 MB, avatars up to 2 MB) and which app may upload which purpose. |
| `MediaFiles` | Upload tickets, confirmation, audited view URLs, deletes and the orphan purge; resolves `IAuditSharedService` on first use. |
| `MediaEventSubscriptions` | `identity.AccountDeleted` runs `DeleteAccountMedia`. |

Mapping: `MediaMappingProfile`. Job: `MediaOrphanPurgeJob` ([jobs](../../Operations/jobs.md)).

## Shared contract

| Method | Contract |
|---|---|
| `CreateUploadUrl` | Validates the request against the purpose's rules and returns a presigned PUT URL (documents: JPEG/PNG/PDF up to 5 MB; avatars: JPEG/PNG up to 2 MB). |
| `ConfirmUpload` | Checks that the object exists and matches the request. |
| `GetObject` | Returns metadata, so callers can check owner and purpose before attaching. |
| `MarkAttached` | Records that a record references the object, sparing it from the orphan purge. |
| `GetViewUrl` | Returns a 5-minute signed GET URL; viewing a verification document writes an audit entry (PRD §6.6). |
| `Delete` | Removes the object from storage and its record. |
| `DeleteOwnerFiles` | Removes every file the account uploaded, documents included (retention purge). |
