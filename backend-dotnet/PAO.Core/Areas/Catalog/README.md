# Catalog area

Categories, services, sub-services and price versions; the published catalog tree and its version.

- Data: `catalog` schema, `DB Changes/catalog/`.
- Contract: `Services/Shared/ICatalogSharedService.cs`, with its DTOs, events and error
  reasons in `PAO.Lib/Areas/Catalog/`. Other areas use only this interface.
- Layout: `Controllers/` (thin, mediator only), `Features/<Feature>/Commands|Queries/`
  (handler, request and validator together), `Services/` (logic shared by several
  handlers), `Repositories/` (EF Core data access).
- Status: skeleton and contract (P17 task 1); the use cases are ported in later P17 tasks.
