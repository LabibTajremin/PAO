# Booking area

Bookings and their state machine (PRD §5): requests, acceptance, start codes, extras, completion, cancellation and timeouts.

- Data: `booking` schema, `DB Changes/booking/`.
- Contract: `Services/Shared/IBookingSharedService.cs`, with its DTOs, events and error
  reasons in `PAO.Lib/Areas/Booking/`. Other areas use only this interface.
- Layout: `Controllers/` (thin, mediator only), `Features/<Feature>/Commands|Queries/`
  (handler, request and validator together), `Services/` (logic shared by several
  handlers), `Repositories/` (EF Core data access).
- Status: skeleton and contract (P17 task 1); the use cases are ported in later P17 tasks.
