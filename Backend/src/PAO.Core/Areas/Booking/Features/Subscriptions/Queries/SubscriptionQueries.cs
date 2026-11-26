using PAO.Core.Areas.Booking.Services;
using PAO.Lib.Areas.Booking;
using PAO.Lib.Errors;
using PAO.Lib.Mapping;
using PAO.Lib.Mediator;

namespace PAO.Core.Areas.Booking.Features.Subscriptions.Queries;

/// <summary>Which subscriptions a list shows: one side's, or every one for support.</summary>
public sealed record SubscriptionScope(Side Side, Guid? PartyId, string? Status);

/// <summary>The newest subscriptions of a scope (at most 100).</summary>
public sealed record ListSubscriptions(SubscriptionScope Scope) : IRequest<SubscriptionListView>;

/// <summary>A subscription with its upcoming dates; support passes no party.</summary>
public sealed record GetSubscription(SubscriptionScope Scope, Guid SubscriptionId) : IRequest<SubscriptionView>;

/// <summary>The merchant's deliveries between two dates, at most 62 days apart, by date and window.</summary>
public sealed record ListProviderDeliveries(Guid ProviderId, DateOnly From, DateOnly To) : IRequest<ProviderDeliveryListView>;

/// <summary>Answers the subscription reads.</summary>
public sealed class SubscriptionQueriesHandler(SubscriptionAccess access, IMapper mapper)
    : IRequestHandler<ListSubscriptions, SubscriptionListView>, IRequestHandler<GetSubscription, SubscriptionView>,
      IRequestHandler<ListProviderDeliveries, ProviderDeliveryListView>
{
    private static readonly string[] Statuses =
        [SubscriptionStatus.Requested, SubscriptionStatus.Active, SubscriptionStatus.Paused, SubscriptionStatus.Finished, SubscriptionStatus.Declined, SubscriptionStatus.Cancelled];

    /// <inheritdoc />
    public async Task<SubscriptionListView> Handle(ListSubscriptions request, CancellationToken cancellationToken)
    {
        var (side, party, status) = request.Scope;
        if (status is not null && !Statuses.Contains(status))
        {
            throw new DomainException(BookingReasons.Invalid);
        }
        var rows = await access.Repository.List(q => q
            .Where(r => side != Side.Customer || r.CustomerId == party)
            .Where(r => side != Side.Provider || r.ProviderId == party)
            .Where(r => status == null || r.Status == status), 100, cancellationToken);
        return new SubscriptionListView([.. rows.Select(s => View(side, s, null))]);
    }

    /// <inheritdoc />
    public async Task<SubscriptionView> Handle(GetSubscription request, CancellationToken cancellationToken)
    {
        var (side, party, _) = request.Scope;
        var s = party is { } id ? await access.Owned(request.SubscriptionId, id, side, cancellationToken)
            : await access.Repository.Get(request.SubscriptionId, cancellationToken);
        return View(side, s, await access.Upcoming(s, cancellationToken));
    }

    /// <inheritdoc />
    public async Task<ProviderDeliveryListView> Handle(ListProviderDeliveries request, CancellationToken cancellationToken)
    {
        var (from, to) = (request.From, request.To);
        if (to < from || to.DayNumber - from.DayNumber > 62)
        {
            throw new DomainException(BookingReasons.Invalid);
        }
        var shown = new[] { SubscriptionStatus.Active, SubscriptionStatus.Paused, SubscriptionStatus.Finished, SubscriptionStatus.Cancelled };
        var subscriptions = await access.Repository.WithDates(
            q => q.Where(r => r.ProviderId == request.ProviderId && shown.Contains(r.Status)), from, to, 500, cancellationToken);
        var holidays = await access.Holidays(cancellationToken);
        var deliveries = subscriptions
            .SelectMany(s => SubscriptionDays.Between(s, from, to, access.Now, holidays)
                .Where(d => d.Status != DeliveryStatus.Skipped || d.BookingId is not null)
                .Select(d => Delivery(s, d)))
            .OrderBy(d => d.Date, StringComparer.Ordinal).ThenBy(d => d.Window.Start, StringComparer.Ordinal);
        return new ProviderDeliveryListView([.. deliveries]);
    }

    private SubscriptionView View(Side side, StoredSubscription s, IReadOnlyList<DayOfSubscription>? days) => side switch
    {
        Side.Customer => mapper.Customer(s, days),
        Side.Provider => mapper.Provider(s, days),
        _ => mapper.Support(s, days),
    };

    private static ProviderDeliveryView Delivery(StoredSubscription s, DayOfSubscription d) => new()
    {
        SubscriptionId = s.Id,
        Number = s.Display,
        Date = EarningsCalendar.Iso(d.Date),
        Window = s.Window,
        Status = d.Status,
        ServiceName = s.ServiceName,
        Items = SubscriptionSides.Inputs(d.Lines),
        Total = d.Lines.Sum(l => l.TotalPaisa),
        Address = SubscriptionSides.Address(s.Address, exact: true),
        CustomerName = s.Customer.Name,
        BookingId = d.BookingId,
    };
}
