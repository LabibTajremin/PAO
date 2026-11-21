using PAO.Lib.Areas.Booking;
using PAO.Lib.Areas.Catalog;
using PAO.Lib.Areas.Merchant;
using PAO.Lib.Common;
using PAO.Lib.Errors;

namespace PAO.Core.Areas.Booking.Services;

/// <summary>
/// Prices items from the current catalog, checks services and the launch area, and checks
/// that both sides of a new booking may take part in it.
/// </summary>
public sealed class BookingPricing(BookingPeers peers, BookingAccess access)
{
    private static readonly string[] BookableModels = ["on_demand", "duration_hire"];

    /// <summary>A published, bookable service; listing and referral services are not booked directly.</summary>
    public async Task<CatalogService> Service(Guid id, CancellationToken cancellationToken)
    {
        var s = await peers.Service(id, cancellationToken);
        return s.Published && BookableModels.Contains(s.Model) ? s : throw new DomainException(BookingReasons.NotBookable);
    }

    /// <summary>
    /// Prices `items` in order from position `first`, with one catalog read for all of them;
    /// every item must be a published sub-service of the booked service.
    /// </summary>
    public async Task<List<BookingLine>> Lines(Guid serviceId, IReadOnlyList<BookingItemInput> items, int first, CancellationToken cancellationToken)
    {
        var prices = await peers.Prices([.. items.Select(i => i.SubServiceId).Distinct()], cancellationToken);
        var lines = new List<BookingLine>(items.Count);
        foreach (var item in items)
        {
            var price = prices.GetValueOrDefault(item.SubServiceId);
            var line = price is { Published: true } && price.ServiceId == serviceId ? BookingStates.NewLine(access.NewId(), price, item.Quantity) : null;
            lines.Add(line is null ? throw new DomainException(BookingReasons.Invalid) : line with { Position = first + lines.Count });
        }
        return lines;
    }

    /// <summary>Throws `booking.outside_area` outside the launch area (D5).</summary>
    public async Task Covered(GeoPoint point, CancellationToken cancellationToken)
    {
        if (!await peers.Covered(point, cancellationToken))
        {
            throw new DomainException(BookingReasons.OutsideArea);
        }
    }

    /// <summary>
    /// Loads both parties: the customer's address must be in the launch area and the
    /// provider must offer the service, be allowed to take it and be online.
    /// </summary>
    public async Task<(BookingParty Customer, AddressSnapshot Address, MerchantProfile Provider)> Sides(
        Guid customerId, Guid addressId, Guid providerId, Guid serviceId, CancellationToken cancellationToken)
    {
        var (name, phone) = await peers.Customer(customerId, cancellationToken);
        var address = await peers.Address(customerId, addressId, cancellationToken);
        await Covered(address.Location, cancellationToken);
        var provider = await peers.Provider(providerId, cancellationToken);
        var ok = provider.ServiceIds.Contains(serviceId)
            && await peers.CanReceiveBookings(providerId, serviceId, cancellationToken)
            && await peers.IsAvailable(providerId, cancellationToken);
        return ok ? (new BookingParty(customerId, name, phone), address, provider) : throw new DomainException(BookingReasons.NotBookable);
    }
}
