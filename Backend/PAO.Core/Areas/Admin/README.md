# Admin area

Admin users, platform settings, complaints and the dashboard statistics.

- Data: `admin` schema, `DB Changes/admin/`.
- Contract: `Services/Shared/IAdminSharedService.cs`, with its DTOs, events and error
  reasons in `PAO.Lib/Areas/Admin/`. Other areas use only this interface.
- Layout: `Controllers/` (thin, mediator only), `Features/<Feature>/Commands|Queries/`
  (handler, request and validator together), `Services/` (logic shared by several
  handlers), `Repositories/` (EF Core data access).
- Status: built in P17 task 4.
