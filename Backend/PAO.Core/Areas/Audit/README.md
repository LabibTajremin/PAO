# Audit area

The append-only audit log; subscribes to every event that changes a person's status or money.

- Data: `audit` schema, `DB Changes/audit/`.
- Contract: `Services/Shared/IAuditSharedService.cs`, with its DTOs, events and error
  reasons in `PAO.Lib/Areas/Audit/`. Other areas use only this interface.
- Layout: `Controllers/` (thin, mediator only), `Features/<Feature>/Commands|Queries/`
  (handler, request and validator together), `Services/` (logic shared by several
  handlers), `Repositories/` (EF Core data access).
- Status: built in P17; see `Docs/Areas/Audit/`.
