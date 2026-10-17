# Media area — overview

Uploads to private buckets through presigned URLs, upload confirmation, signed view URLs and the orphan purge.

Code: `PAO.Core/Areas/Media/`; contracts: `PAO.Lib/Areas/Media/`. Back to the [area index](../README.md).

## Services

| Service | Role |
|---|---|
| `IMediaSharedService` | The only way other areas reach Media (`Services/Shared/`). Implemented when the use cases are ported. |

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
