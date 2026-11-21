using PAO.Core.Areas.Audit.Services.Shared;
using PAO.Core.Areas.Booking.Services.Shared;
using PAO.Core.Areas.Catalog.Services.Shared;
using PAO.Core.Areas.Customer.Services.Shared;
using PAO.Core.Areas.Identity.Services.Shared;
using PAO.Core.Areas.Media.Services.Shared;
using PAO.Core.Areas.Merchant.Services.Shared;
using PAO.Core.Areas.Rating.Services.Shared;
using PAO.Core.Areas.Verification.Services.Shared;
using PAO.Lib.Areas.Admin;
using PAO.Lib.Areas.Booking;
using PAO.Lib.Areas.Identity;
using PAO.Lib.Areas.Media;
using PAO.Lib.Errors;

namespace PAO.Core.Areas.Admin.Services;

/// <summary>
/// The areas that own what the admin console shows (ADR-0026), resolved on first use,
/// because several of them read the admin settings themselves.
/// </summary>
public sealed class AdminPeers(IServiceProvider services)
{
    /// <summary>Merchant profiles and search.</summary>
    public IMerchantSharedService Merchants => services.GetRequiredService<IMerchantSharedService>();
    /// <summary>Customer search.</summary>
    public ICustomerSharedService Customers => services.GetRequiredService<ICustomerSharedService>();
    /// <summary>Verification items and the review queue.</summary>
    public IVerificationSharedService Verification => services.GetRequiredService<IVerificationSharedService>();
    /// <summary>Bookings.</summary>
    public IBookingSharedService Bookings => services.GetRequiredService<IBookingSharedService>();
    /// <summary>Ratings.</summary>
    public IRatingSharedService Ratings => services.GetRequiredService<IRatingSharedService>();
    /// <summary>Accounts and their status.</summary>
    public IIdentitySharedService Identity => services.GetRequiredService<IIdentitySharedService>();
    /// <summary>Status history.</summary>
    public IAuditSharedService Audit => services.GetRequiredService<IAuditSharedService>();
    /// <summary>Service names.</summary>
    public ICatalogSharedService Catalog => services.GetRequiredService<ICatalogSharedService>();

    /// <summary>The booking's parties; `admin.booking_not_found` for an unknown booking.</summary>
    public async Task<(Guid CustomerId, Guid ProviderId)> Parties(Guid bookingId, CancellationToken cancellationToken)
    {
        try
        {
            var b = await Bookings.GetBooking(bookingId, cancellationToken);
            return (b.CustomerId, b.ProviderId);
        }
        catch (DomainException error) when (error.Reason == BookingErrors.NotFound)
        {
            throw new DomainException(AdminReasons.BookingNotFound, error);
        }
    }

    /// <summary>
    /// Checks that every photo is the owner's confirmed complaint photo before any is marked
    /// attached, so a refused report leaves its photos to the orphan purge.
    /// </summary>
    public async Task AttachPhotos(Guid ownerId, IReadOnlyList<Guid> mediaIds, CancellationToken cancellationToken)
    {
        var media = services.GetRequiredService<IMediaSharedService>();
        foreach (var id in mediaIds)
        {
            MediaObject? o;
            try
            {
                o = await media.GetObject(id, cancellationToken);
            }
            catch (DomainException error) when (error.Reason == MediaErrors.NotFound)
            {
                o = null;
            }
            if (o is null || o.OwnerId != ownerId || o.Purpose != MediaPurpose.ComplaintPhoto || !o.Confirmed)
            {
                throw new DomainException(AdminReasons.PhotoInvalid);
            }
        }
        foreach (var id in mediaIds)
        {
            await media.MarkAttached(id, cancellationToken);
        }
    }

    /// <summary>Whether the account is an active support agent or super admin.</summary>
    public async Task<bool> CanWorkComplaints(Guid accountId, CancellationToken cancellationToken)
    {
        try
        {
            var a = await Identity.GetAccount(accountId, cancellationToken);
            return a.Status == AccountStatus.Active && (a.Roles.Contains(Roles.SupportAgent) || a.Roles.Contains(Roles.SuperAdmin));
        }
        catch (DomainException error) when (error.Reason == IdentityErrors.AccountNotFound)
        {
            return false;
        }
    }
}
