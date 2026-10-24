# Rating area

Reviews after completed bookings and the rating aggregates of merchants and customers.

- Data: `rating` schema, `DB Changes/rating/`.
- Contract: `Services/Shared/IRatingSharedService.cs`, with its DTOs, events and error
  reasons in `PAO.Lib/Areas/Rating/`. Other areas use only this interface.
- Layout: `Controllers/` (thin, mediator only), `Features/<Feature>/Commands|Queries/`
  (handler, request and validator together), `Services/` (logic shared by several
  handlers), `Repositories/` (EF Core data access).
- Status: ported from NestJS in P17 task 4.
