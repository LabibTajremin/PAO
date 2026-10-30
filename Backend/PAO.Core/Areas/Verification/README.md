# Verification area

Verification items and documents, NID records, levels, Level 2 sessions, expiry and reminders, and the purge of closed accounts' documents.

- Data: `verification` schema, `DB Changes/verification/`.
- Contract: `Services/Shared/IVerificationSharedService.cs`, with its DTOs, events and error
  reasons in `PAO.Lib/Areas/Verification/`. Other areas use only this interface.
- Layout: `Controllers/` (thin, mediator only), `Features/<Feature>/Commands|Queries/`
  (handler, request and validator together), `Services/` (logic shared by several
  handlers), `Repositories/` (EF Core data access).
- Status: ported (P17); see `Docs/Areas/Verification/`.
