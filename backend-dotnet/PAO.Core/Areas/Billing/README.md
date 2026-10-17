# Billing area

Cash on delivery and merchant dues (ADR-0035): the commission ledger, the due limit on accept, merchant payment submissions and admin review. Its schema and operations arrive in P17 task 5.

- Data: no schema yet.
- Contract: `Services/Shared/IBillingSharedService.cs`, with its DTOs, events and error
  reasons in `PAO.Lib/Areas/Billing/`. Other areas use only this interface.
- Layout: `Controllers/` (thin, mediator only), `Features/<Feature>/Commands|Queries/`
  (handler, request and validator together), `Services/` (logic shared by several
  handlers), `Repositories/` (EF Core data access).
- Status: skeleton and contract (P17 task 1); the use cases are ported in later P17 tasks.
