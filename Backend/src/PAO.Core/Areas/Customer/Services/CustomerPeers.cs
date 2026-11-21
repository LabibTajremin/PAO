using PAO.Core.Areas.Admin.Services.Shared;
using PAO.Core.Areas.Identity.Services.Shared;
using PAO.Core.Areas.Media.Services.Shared;
using PAO.Lib.Areas.Customer;
using PAO.Lib.Areas.Media;
using PAO.Lib.Errors;

namespace PAO.Core.Areas.Customer.Services;

/// <summary>
/// Media, Identity and Admin as the Customer area needs them. Their contracts are resolved
/// on first use, so Customer starts whichever areas are wired and Admin's dependency on
/// Customer cannot form a cycle.
/// </summary>
public sealed class CustomerPeers(IServiceProvider services)
{
    /// <summary>
    /// Checks that `mediaId` is a confirmed avatar upload owned by `ownerId` and marks it
    /// attached; `customer.invalid_photo` otherwise.
    /// </summary>
    public async Task AttachAvatar(Guid ownerId, Guid mediaId, CancellationToken cancellationToken)
    {
        var media = services.GetRequiredService<IMediaSharedService>();
        MediaObject? found;
        try
        {
            found = await media.GetObject(mediaId, cancellationToken);
        }
        catch (DomainException error) when (error.Reason == MediaErrors.NotFound)
        {
            found = null;
        }
        if (found is null || found.OwnerId != ownerId || found.Purpose != MediaPurpose.Avatar || !found.Confirmed)
        {
            throw new DomainException(CustomerReasons.InvalidPhoto);
        }
        await media.MarkAttached(mediaId, cancellationToken);
    }

    /// <summary>A short-lived URL for showing the photo to its owner.</summary>
    public async Task<string> PhotoUrl(Guid viewerId, Guid mediaId, CancellationToken cancellationToken) =>
        (await services.GetRequiredService<IMediaSharedService>()
            .GetViewUrl(new ViewRequest { MediaId = mediaId, ViewerId = viewerId, ViewerRole = "customer" }, cancellationToken)).Url;

    /// <summary>The account's phone and status, owned by Identity.</summary>
    public async Task<(string Phone, string Status)> Account(Guid accountId, CancellationToken cancellationToken)
    {
        var account = await services.GetRequiredService<IIdentitySharedService>().GetAccount(accountId, cancellationToken);
        return (account.Phone, account.Status);
    }

    /// <summary>The launch area from the admin settings; empty means everywhere.</summary>
    public async Task<string> LaunchAreaGeoJson(CancellationToken cancellationToken) =>
        (await services.GetRequiredService<IAdminSharedService>().GetSettings(cancellationToken)).ServiceAreaGeoJson;
}
