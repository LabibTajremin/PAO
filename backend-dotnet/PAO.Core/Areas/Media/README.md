# Media area

Uploads to private buckets through presigned URLs, upload confirmation, signed view URLs and the orphan purge.

- Data: `media` schema, `DB Changes/media/`.
- Contract: `Services/Shared/IMediaSharedService.cs`, with its DTOs, events and error
  reasons in `PAO.Lib/Areas/Media/`. Other areas use only this interface.
- Layout: `Controllers/` (thin, mediator only), `Features/<Feature>/Commands|Queries/`
  (handler, request and validator together), `Services/` (logic shared by several
  handlers), `Repositories/` (EF Core data access).
- Status: skeleton and contract (P17 task 1); the use cases are ported in later P17 tasks.
