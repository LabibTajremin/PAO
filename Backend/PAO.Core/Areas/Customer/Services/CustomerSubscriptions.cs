using PAO.Core.Areas.Customer.Repositories;
using PAO.EF;
using PAO.Infrastructure.Events;
using PAO.Infrastructure.Outbox;
using PAO.Lib.Areas.Booking;
using PAO.Lib.Areas.Identity;

namespace PAO.Core.Areas.Customer.Services;

/// <summary>
/// Erases deleted accounts and keeps the admin list copies (status, bookings) current, each
/// event applied once per handler.
/// </summary>
public sealed class CustomerSubscriptions(IdempotentEventHandler idempotent) : IEventSubscriptions
{
    // Keyed by handler name in processed_events; the names are Go's and NestJS's, so events
    // those workers already applied stay skipped.
    private static readonly (string Handler, string Event, Func<PaoDbContext, EventPayload, CancellationToken, Task> Apply)[] Handlers =
    [
        ("erase_account", IdentityEvents.AccountDeleted, (db, p, ct) => CustomerRepository.Erase(db, Required(p, "accountId"), ct)),
        (IdentityEvents.AccountStatusChanged, IdentityEvents.AccountStatusChanged, StatusChanged),
        (BookingEvents.BookingRequested, BookingEvents.BookingRequested, BookingRequested),
    ];

    /// <inheritdoc />
    public void Subscribe(EventBus bus)
    {
        foreach (var (handler, name, apply) in Handlers)
        {
            bus.Subscribe(name, Schemas.Customer, idempotent.Wrap(Schemas.Customer, handler, (db, envelope, ct) => apply(db, new EventPayload(envelope), ct)));
        }
    }

    private static async Task StatusChanged(PaoDbContext db, EventPayload p, CancellationToken cancellationToken)
    {
        var id = Required(p, "accountId");
        var status = p.Text("to");
        if (p.Texts("roles").Contains(Roles.Customer))
        {
            await CustomerRepository.SetStatus(db, id, status, cancellationToken);
        }
    }

    /// <summary>An id the handler cannot do without; a malformed event fails so the relay retries it.</summary>
    private static Guid Required(EventPayload p, string name)
    {
        var id = Guid.Parse(p.Id(name));
        return id == Guid.Empty ? throw new FormatException($"decode: {name} is missing") : id;
    }

    // A missing customer id reads as the nil UUID, as Go decoded it: the count touches no row.
    private static Task BookingRequested(PaoDbContext db, EventPayload p, CancellationToken cancellationToken) =>
        CustomerRepository.CountBooking(db, Guid.Parse(p.Id("customerId")), cancellationToken);
}
