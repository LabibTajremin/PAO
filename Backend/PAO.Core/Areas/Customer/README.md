# Customer area

Customer profiles, saved addresses and launch areas.

- Data: `customer` schema, `DB Changes/customer/`.
- Contract: `Services/Shared/ICustomerSharedService.cs`, with its DTOs, events and error
  reasons in `PAO.Lib/Areas/Customer/`. Other areas use only this interface.
- Layout: `Controllers/` (thin, mediator only), `Features/<Feature>/Commands|Queries/`
  (handler, request and validator together), `Services/` (logic shared by several
  handlers), `Repositories/` (EF Core data access).
- Status: skeleton and contract (P17 task 1); the use cases are ported in later P17 tasks.
