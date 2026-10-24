# Merchant area

Merchant (provider) profiles, the enrolment wizard, services offered, presence and nearby search. "Merchant" is the owner's name for the provider role; the schema, events and API paths keep `provider`.

- Data: `provider` schema, `DB Changes/provider/`.
- Contract: `Services/Shared/IMerchantSharedService.cs`, with its DTOs, events and error
  reasons in `PAO.Lib/Areas/Merchant/`. Other areas use only this interface.
- Layout: `Controllers/` (thin, mediator only), `Features/<Feature>/Commands|Queries/`
  (handler, request and validator together), `Services/` (logic shared by several
  handlers), `Repositories/` (EF Core data access).
- Status: skeleton and contract (P17 task 1); the use cases are ported in later P17 tasks.
