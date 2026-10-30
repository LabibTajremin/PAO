# Identity area

Accounts, roles, permissions and screen permissions; phone OTP sign-in for customers and merchants, email, password and TOTP for admins; refresh-token families and the access-token denylist.

- Data: `identity` schema, `DB Changes/identity/`.
- Contract: `Services/Shared/IIdentitySharedService.cs`, with its DTOs, events and error
  reasons in `PAO.Lib/Areas/Identity/`. Other areas use only this interface.
- Layout: `Controllers/` (thin, mediator only), `Features/<Feature>/Commands|Queries/`
  (handler, request and validator together), `Services/` (logic shared by several
  handlers), `Repositories/` (EF Core data access).
- Status: built in P17; see `Docs/Areas/Identity/`.
