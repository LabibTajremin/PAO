# Billing area

Cash on delivery and merchant dues (ADR-0035): the commission ledger, the due limit on accept,
merchant payment submissions and admin review.

- Data: schema `billing` (`DB Changes/billing/`); see `Docs/Areas/Billing/data.md`.
- Contract: `Services/Shared/IBillingSharedService.cs`, with its DTOs, events and error
  reasons in `PAO.Lib/Areas/Billing/`. Other areas use only this interface.
- Layout: `Controllers/` (thin, mediator only), `Features/<Feature>/Commands|Queries/`
  (handler, request and validator together), `Services/` (logic shared by several
  handlers), `Repositories/` (EF Core data access).
- The due and its rules: `Docs/Areas/Billing/overview.md`.
