using PAO.Core.Areas.Admin.Services.Shared;
using PAO.Core.Areas.Billing.Services.Shared;
using PAO.Core.Areas.Catalog.Services.Shared;
using PAO.Core.Areas.Customer.Services.Shared;
using PAO.Core.Areas.Identity.Services.Shared;
using PAO.Core.Areas.Media.Services.Shared;
using PAO.Core.Areas.Merchant.Services.Shared;
using PAO.Core.Areas.Rating.Services.Shared;
using PAO.Core.Areas.Verification.Services.Shared;
using PAO.Lib.Areas.Admin;
using PAO.Lib.Areas.Billing;
using PAO.Lib.Areas.Booking;
using PAO.Lib.Areas.Catalog;
using PAO.Lib.Areas.Customer;
using PAO.Lib.Areas.Media;
using PAO.Lib.Areas.Merchant;
using PAO.Lib.Common;
using PAO.Lib.Errors;

namespace PAO.Core.Areas.Booking.Services;

/// <summary>
/// The areas Booking reads, resolved on first use, so Booking starts whichever areas are
/// wired and never forms a construction cycle with the areas that read bookings. Their
/// failures are rethrown as booking reasons where the API answers differently.
/// </summary>
public sealed class BookingPeers(IServiceProvider services)
{
    /// <summary>A catalog service; `booking.not_found` when there is none.</summary>
    public Task<CatalogService> Service(Guid id, CancellationToken cancellationToken) =>
        Translate(() => Get<ICatalogSharedService>().GetService(id, cancellationToken), CatalogErrors.ServiceNotFound, BookingReasons.NotFound);

    /// <summary>The current prices of the sub-services among `ids` that exist, by id, in one round.</summary>
    public async Task<IReadOnlyDictionary<Guid, PriceSnapshot>> Prices(IReadOnlyCollection<Guid> ids, CancellationToken cancellationToken) =>
        (await Get<ICatalogSharedService>().GetPriceSnapshots(ids, cancellationToken)).ToDictionary(p => p.SubServiceId);

    /// <summary>The customer's profile name and phone; `booking.profile_required` without a profile.</summary>
    public async Task<(string Name, string Phone)> Customer(Guid id, CancellationToken cancellationToken)
    {
        var c = await Translate(() => Get<ICustomerSharedService>().GetCustomer(id, cancellationToken), CustomerErrors.NotFound, BookingReasons.ProfileRequired);
        var account = await Get<IIdentitySharedService>().GetAccount(id, cancellationToken);
        return (c.Name, account.Phone);
    }

    /// <summary>One of the customer's addresses; another customer's or an unknown one is `booking.invalid`.</summary>
    public async Task<AddressSnapshot> Address(Guid customerId, Guid addressId, CancellationToken cancellationToken)
    {
        var a = await Translate(() => Get<ICustomerSharedService>().GetAddress(customerId, addressId, cancellationToken), CustomerErrors.AddressNotFound, BookingReasons.Invalid);
        return new AddressSnapshot(a.Id, a.Area, a.Line1, a.Line2, a.Location);
    }

    /// <summary>Reports whether the point is inside the launch area (D5).</summary>
    public Task<bool> Covered(GeoPoint point, CancellationToken cancellationToken) =>
        Get<ICustomerSharedService>().IsInServiceArea(point, cancellationToken);

    /// <summary>The provider's name, phone and services; an unknown provider is `booking.not_bookable`.</summary>
    public Task<MerchantProfile> Provider(Guid id, CancellationToken cancellationToken) =>
        Translate(() => Get<IMerchantSharedService>().GetMerchant(id, cancellationToken), MerchantErrors.NotFound, BookingReasons.NotBookable);

    /// <summary>Whether the provider is online.</summary>
    public Task<bool> IsAvailable(Guid id, CancellationToken cancellationToken) => Get<IMerchantSharedService>().IsAvailable(id, cancellationToken);

    /// <summary>Whether Verification lets the provider take the service.</summary>
    public Task<bool> CanReceiveBookings(Guid id, Guid serviceId, CancellationToken cancellationToken) =>
        Get<IVerificationSharedService>().CanReceiveBookings(id, serviceId, cancellationToken);

    /// <summary>Verified, online providers around a point.</summary>
    public Task<IReadOnlyList<NearbyMerchant>> FindNearby(NearbyQuery query, CancellationToken cancellationToken) =>
        Get<IMerchantSharedService>().FindNearby(query, cancellationToken);

    /// <summary>A signed photo URL for the customer, or null when it cannot be signed: the card works without it.</summary>
    public async Task<string?> PhotoUrl(Guid viewerId, Guid mediaId, CancellationToken cancellationToken)
    {
        try
        {
            var view = new ViewRequest { MediaId = mediaId, ViewerId = viewerId, ViewerRole = "customer" };
            return (await Get<IMediaSharedService>().GetViewUrl(view, cancellationToken)).Url;
        }
        catch (Exception error) when (error is not OperationCanceledException)
        {
            return null;
        }
    }

    /// <summary>The admin-editable booking rules (D12).</summary>
    public Task<PlatformSettings> Rules(CancellationToken cancellationToken) => Get<IAdminSharedService>().GetSettings(cancellationToken);

    /// <summary>Whether the author already reviewed the booking.</summary>
    public Task<bool> HasReviewed(Guid bookingId, Guid authorId, CancellationToken cancellationToken) =>
        Get<IRatingSharedService>().HasReviewed(bookingId, authorId, cancellationToken);

    /// <summary>
    /// The one check before an accept that Billing owns (ADR-0035 §3): a merchant whose due is
    /// above the block limit cannot accept. Billing arrives in P17 task 5; until its shared
    /// service is registered there is no due to check. The refusal carries both amounts so
    /// the partner app can say how much to pay.
    /// </summary>
    public async Task EnsureCanAccept(Guid merchantId, CancellationToken cancellationToken)
    {
        if (services.GetService<IBillingSharedService>() is not { } billing)
        {
            return;
        }
        var due = await billing.GetDueStatus(merchantId, cancellationToken);
        if (due.Blocked)
        {
            throw new DomainException(BillingErrors.DueLimit)
            {
                Details = new Dictionary<string, object?> { ["duePaisa"] = due.DuePaisa, ["blockAmountPaisa"] = due.BlockAmountPaisa },
            };
        }
    }

    private T Get<T>()
        where T : notnull => services.GetRequiredService<T>();

    private static async Task<T> Translate<T>(Func<Task<T>> call, string from, string to)
    {
        try
        {
            return await call();
        }
        catch (DomainException error) when (error.Reason == from)
        {
            throw new DomainException(to, error);
        }
    }
}
