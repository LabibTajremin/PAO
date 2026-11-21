# Media area — features

One entry per feature folder (`Features/<Feature>/Commands|Queries/`): the use case, its
request, validator and handler. Overview: [overview.md](overview.md).

| Feature | Use case | Kind | Notes |
|---|---|---|---|
| `Uploads` | `CreateUpload` | command | the validator refuses a purpose, type or size the app may not upload (UPLOAD_INVALID) before anything is stored; a 15-minute presigned PUT that signs type and length |
| `Uploads` | `ConfirmUpload` | command | checks the stored size and type; a mismatch deletes the file (409); confirming twice is harmless |
| `Documents` | `GetDocumentViewUrl` | query | 5-minute signed GET; verification documents are audited first (`media.document_viewed`) |
| `Retention` | `PurgeOrphanMedia`, `DeleteAccountMedia` | command | the `media.purge_orphans` job, and erasure on `identity.AccountDeleted` (documents kept) |
