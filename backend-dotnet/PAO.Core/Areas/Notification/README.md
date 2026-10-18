# Notification area

Templates, the inbox, device tokens and delivery by push and SMS; subscribes to booking and verification events.

- Data: `notification` schema, `DB Changes/notification/`.
- Contract: `Services/Shared/INotificationSharedService.cs`, with its DTOs, events and error
  reasons in `PAO.Lib/Areas/Notification/`. Other areas use only this interface.
- Layout: `Controllers/` (thin, mediator only), `Features/<Feature>/Commands|Queries/`
  (handler, request and validator together), `Services/` (logic shared by several
  handlers), `Repositories/` (EF Core data access).
- Status: ported from NestJS (P17 task 2); see `Docs/Areas/<area>/`.
