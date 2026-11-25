using PAO.Core.Areas.Booking.Repositories;
using PAO.Infrastructure.Data;
using PAO.Lib.Areas.Booking;
using PAO.Lib.Common;
using PAO.Lib.Errors;
using PAO.Lib.Events;

namespace PAO.Core.Areas.Booking.Services;

/// <summary>
/// Loads and changes subscriptions for one party, hiding other people's as not found, and
/// stamps the fields every subscription event carries.
/// </summary>
public sealed class SubscriptionAccess(SubscriptionRepository repository, BookingPeers peers, IClock clock, IIdGenerator ids)
{
    /// <summary>The repository.</summary>
    public SubscriptionRepository Repository => repository;

    /// <summary>The current instant.</summary>
    public DateTimeOffset Now => clock.Now;

    /// <summary>A new id.</summary>
    public Guid NewId() => ids.NewId();

    /// <summary>The admin's holidays, when no deliveries happen.</summary>
    public async Task<IReadOnlySet<DateOnly>> Holidays(CancellationToken cancellationToken) =>
        DeliveryCalendar.Holidays((await peers.Rules(cancellationToken)).DeliveryHolidays);

    /// <summary>Fills the fields every subscription event carries.</summary>
    public T Event<T>(T e, StoredSubscription s)
        where T : SubscriptionEvent => e with
        {
            SubscriptionId = s.Id,
            Number = s.Display,
            CustomerId = s.Customer.Id,
            ProviderId = s.Provider.Id,
            ServiceId = s.ServiceId,
            ServiceEn = s.ServiceName.En,
            ServiceBn = s.ServiceName.Bn,
            At = IsoTime.Format(clock.Now),
        };

    /// <summary>A subscription the party takes part in, on <paramref name="side"/>.</summary>
    public async Task<StoredSubscription> Owned(Guid id, Guid party, Side side, CancellationToken cancellationToken)
    {
        var s = await repository.Get(id, cancellationToken);
        return TakesPart(s, party, side) ? s : throw new DomainException(BookingReasons.NotFound);
    }

    /// <summary>Applies <paramref name="change"/> to a subscription the party takes part in, publishing its event.</summary>
    public Task<StoredSubscription> Change(Guid id, Guid party, Side side, Func<StoredSubscription, IDomainEvent?> change, CancellationToken cancellationToken) =>
        repository.Change(id, s =>
        {
            var e = TakesPart(s, party, side) ? change(s) : throw new DomainException(BookingReasons.NotFound);
            return e is null ? [] : [e];
        }, cancellationToken);

    /// <summary>The dates from today to the horizon, as the apps list them.</summary>
    public async Task<IReadOnlyList<DayOfSubscription>> Upcoming(StoredSubscription s, CancellationToken cancellationToken)
    {
        var today = DeliveryCalendar.Today(clock.Now);
        return SubscriptionDays.Between(s, today, today.AddDays(SubscriptionDays.Horizon), clock.Now, await Holidays(cancellationToken));
    }

    private static bool TakesPart(StoredSubscription s, Guid party, Side side) => side switch
    {
        Side.Customer => s.Customer.Id == party,
        Side.Provider => s.Provider.Id == party,
        _ => s.Customer.Id == party || s.Provider.Id == party,
    };
}
