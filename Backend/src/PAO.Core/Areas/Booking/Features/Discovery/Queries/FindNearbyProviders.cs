using FluentValidation;
using PAO.Core.Areas.Booking.Services;
using PAO.Infrastructure.Http;
using PAO.Lib.Areas.Booking;
using PAO.Lib.Areas.Merchant;
using PAO.Lib.Common;
using PAO.Lib.Errors;
using PAO.Lib.Mediator;

namespace PAO.Core.Areas.Booking.Features.Discovery.Queries;

/// <summary>Prices a sub-service and lists verified, online providers around the customer (C10, PRD §5).</summary>
public sealed record FindNearbyProviders(Guid CustomerId, NearbyInput Input) : IQuery<NearbyProvidersView>;

/// <summary>Checks <see cref="FindNearbyProviders"/>.</summary>
public sealed class FindNearbyProvidersValidator : AbstractValidator<FindNearbyProviders>
{
    /// <summary>A saved address or a whole point to search around.</summary>
    public FindNearbyProvidersValidator() => RuleFor(r => r.Input).Custom((q, _) =>
    {
        if (q.AddressId is null && (q.Lat is null || q.Lng is null))
        {
            throw new DomainException(BookingReasons.Invalid);
        }
    });
}

/// <summary>Answers <see cref="FindNearbyProviders"/>; search only returns verified providers, so the badge follows the level.</summary>
public sealed class FindNearbyProvidersHandler(BookingPricing pricing, BookingPeers peers) : IRequestHandler<FindNearbyProviders, NearbyProvidersView>
{
    /// <inheritdoc />
    public async Task<NearbyProvidersView> Handle(FindNearbyProviders request, CancellationToken cancellationToken)
    {
        var q = request.Input;
        var service = await pricing.Service(q.ServiceId, cancellationToken);
        var price = (await pricing.Lines(q.ServiceId, [new BookingItemInput { SubServiceId = q.SubServiceId, Quantity = q.Quantity }], 0, cancellationToken))[0];
        var at = q.AddressId is { } a
            ? (await peers.Address(request.CustomerId, a, cancellationToken)).Location
            : new GeoPoint { Lat = q.Lat!.Value, Lng = q.Lng!.Value };
        await pricing.Covered(at, cancellationToken);
        var found = await peers.FindNearby(new NearbyQuery
        {
            ServiceId = q.ServiceId,
            Point = at,
            RadiusM = service.SearchRadiusM,
            WomenProvidersOnly = service.WomenProvidersOnly,
            Sort = q.Sort == "rating" ? "rating" : "distance",
            Limit = Cursor.PageSize(q.Limit),
        }, cancellationToken);
        var cards = new List<ProviderCardView>(found.Count);
        foreach (var n in found)
        {
            cards.Add(await Card(request.CustomerId, n, cancellationToken));
        }
        return new NearbyProvidersView
        {
            Items = cards,
            PriceSummary = new PriceSummaryView { SubServiceId = price.SubServiceId, Quantity = price.Quantity, UnitPrice = price.UnitPaisa, Total = price.TotalPaisa },
        };
    }

    /// <summary>A card with a signed photo URL when one could be signed.</summary>
    private async Task<ProviderCardView> Card(Guid viewer, NearbyMerchant n, CancellationToken cancellationToken) => new()
    {
        Id = n.ProviderId,
        Name = n.Name,
        Level = n.Level,
        Rating = n.Rating,
        RatingCount = n.RatingCount,
        CompletedJobs = n.CompletedJobs,
        DistanceM = (int)Math.Truncate(n.DistanceM),
        Badge = n.Level >= 2 ? "verified_pro" : "verified",
        PhotoUrl = n.PhotoMediaId is { } photo ? await peers.PhotoUrl(viewer, photo, cancellationToken) : null,
    };
}
