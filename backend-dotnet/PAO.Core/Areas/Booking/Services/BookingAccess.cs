using PAO.Core.Areas.Booking.Repositories;
using PAO.Infrastructure.Data;
using PAO.Lib.Areas.Booking;
using PAO.Lib.Common;
using PAO.Lib.Errors;
using PAO.Lib.Events;

namespace PAO.Core.Areas.Booking.Services;

/// <summary>Which side of a booking a caller acts on.</summary>
public enum Side
{
    /// <summary>Either side.</summary>
    Any,
    /// <summary>The customer who booked.</summary>
    Customer,
    /// <summary>The provider booked.</summary>
    Provider,
}

/// <summary>
/// Loads and changes bookings for one party, hiding other people's bookings as not found,
/// and stamps the fields every booking event carries.
/// </summary>
public sealed class BookingAccess(BookingRepository repository, BookingQueries queries, IClock clock, IIdGenerator ids)
{
    /// <summary>The repository, for use cases that change without a party.</summary>
    public BookingRepository Repository => repository;

    /// <summary>The reads.</summary>
    public BookingQueries Queries => queries;

    /// <summary>The current instant.</summary>
    public DateTimeOffset Now => clock.Now;

    /// <summary>A new id.</summary>
    public Guid NewId() => ids.NewId();

    /// <summary>A timeline stamp for now.</summary>
    public Stamp Stamp() => new(clock.Now, ids.NewId());

    /// <summary>Fills the fields every booking event carries (who it concerns and when).</summary>
    public T Event<T>(T e, StoredBooking b)
        where T : BookingEvent => e with
    {
        BookingId = b.Id,
        Number = b.DisplayNumber,
        CustomerId = b.Customer.Id,
        ProviderId = b.Provider.Id,
        ServiceId = b.ServiceId,
        At = IsoTime.Format(clock.Now),
    };

    /// <summary>A booking the party takes part in, on `side`.</summary>
    public async Task<StoredBooking> Owned(Guid id, Guid party, Side side, CancellationToken cancellationToken)
    {
        var b = await queries.Get(id, cancellationToken);
        return TakesPart(b, party, side) ? b : throw new DomainException(BookingReasons.NotFound);
    }

    /// <summary>Applies `change` to a booking the party takes part in on `side`.</summary>
    public Task<StoredBooking> Change(Guid id, Guid party, Side side, BookingChange change, CancellationToken cancellationToken) =>
        repository.Change(id, b => TakesPart(b, party, side) ? change(b) : throw new DomainException(BookingReasons.NotFound), cancellationToken);

    /// <summary>Applies a provider-side change that publishes the event `change` returns.</summary>
    public Task<StoredBooking> AsProvider(Guid id, Guid provider, Func<StoredBooking, IDomainEvent?> change, CancellationToken cancellationToken) =>
        Change(id, provider, Side.Provider, b => Task.FromResult<IReadOnlyList<IDomainEvent>>(change(b) is { } e ? [e] : []), cancellationToken);

    /// <summary>Throws the refusal of a rule.</summary>
    public static void Refuse(string? reason)
    {
        if (reason is not null)
        {
            throw new DomainException(reason);
        }
    }

    private static bool TakesPart(StoredBooking b, Guid party, Side side) => side switch
    {
        Side.Customer => b.Customer.Id == party,
        Side.Provider => b.Provider.Id == party,
        _ => b.Customer.Id == party || b.Provider.Id == party,
    };
}
