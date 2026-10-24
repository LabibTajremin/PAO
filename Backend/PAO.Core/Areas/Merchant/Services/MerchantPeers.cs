using PAO.Core.Areas.Admin.Services.Shared;
using PAO.Core.Areas.Catalog.Services.Shared;
using PAO.Core.Areas.Identity.Services.Shared;
using PAO.Core.Areas.Media.Services.Shared;
using PAO.Core.Areas.Rating.Services.Shared;
using PAO.Lib.Areas.Admin;
using PAO.Lib.Areas.Catalog;
using PAO.Lib.Areas.Identity;
using PAO.Lib.Areas.Media;
using PAO.Lib.Areas.Merchant;
using PAO.Lib.Areas.Rating;
using PAO.Lib.Errors;

namespace PAO.Core.Areas.Merchant.Services;

/// <summary>
/// Catalog, Identity, Media, Admin and Rating as the Merchant area needs them. Their
/// contracts are resolved on first use, so Merchant starts whichever areas are wired and the
/// cycles with Verification and Identity cannot form.
/// </summary>
public sealed class MerchantPeers(IServiceProvider services)
{
    private static readonly string[] RejectedCodes = [IdentityErrors.CodeInvalid, IdentityErrors.CodeExpired, IdentityErrors.CodeLocked];

    /// <summary>A catalog service; `provider.unknown_service` when the catalog has none with the id.</summary>
    public async Task<MerchantService> Service(Guid id, CancellationToken cancellationToken)
    {
        try
        {
            return ToService(await services.GetRequiredService<ICatalogSharedService>().GetService(id, cancellationToken));
        }
        catch (DomainException error) when (error.Reason == CatalogErrors.ServiceNotFound)
        {
            throw new DomainException(MerchantReasons.UnknownService, error);
        }
    }

    /// <summary>
    /// The services in `ids` order, from the catalog's cached published list; only a service
    /// that is not published is looked up on its own.
    /// </summary>
    public async Task<IReadOnlyList<MerchantService>> Services(IReadOnlyList<Guid> ids, CancellationToken cancellationToken)
    {
        if (ids.Count == 0)
        {
            return [];
        }
        var published = (await services.GetRequiredService<ICatalogSharedService>().ListServices(cancellationToken))
            .Where(s => ids.Contains(s.Id)).ToDictionary(s => s.Id, ToService);
        var found = new List<MerchantService>(ids.Count);
        foreach (var id in ids)
        {
            found.Add(published.TryGetValue(id, out var s) ? s : await Service(id, cancellationToken));
        }
        return found;
    }

    /// <summary>The account phone, owned by Identity.</summary>
    public async Task<string> Phone(Guid id, CancellationToken cancellationToken) =>
        (await services.GetRequiredService<IIdentitySharedService>().GetAccount(id, cancellationToken)).Phone;

    /// <summary>Sends the guarantor a one-time code.</summary>
    public Task SendContactCode(string phone, CancellationToken cancellationToken) =>
        Codes(() => services.GetRequiredService<IIdentitySharedService>().SendPhoneCode(phone, CodePurpose.EmergencyContact, cancellationToken));

    /// <summary>Checks the code the guarantor received.</summary>
    public Task CheckContactCode(string phone, string code, CancellationToken cancellationToken) =>
        Codes(() => services.GetRequiredService<IIdentitySharedService>().CheckPhoneCode(phone, CodePurpose.EmergencyContact, code, cancellationToken));

    /// <summary>Checks that `mediaId` is the owner's confirmed avatar and marks it attached; `provider.invalid_photo` otherwise.</summary>
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
            throw new DomainException(MerchantReasons.InvalidPhoto);
        }
        await media.MarkAttached(mediaId, cancellationToken);
    }

    /// <summary>A short-lived URL for showing the photo.</summary>
    public async Task<string> PhotoUrl(Guid viewerId, Guid mediaId, CancellationToken cancellationToken) =>
        (await services.GetRequiredService<IMediaSharedService>()
            .GetViewUrl(new ViewRequest { MediaId = mediaId, ViewerId = viewerId, ViewerRole = "provider" }, cancellationToken)).Url;

    /// <summary>The quality thresholds from the admin settings (D13).</summary>
    public Task<PlatformSettings> Settings(CancellationToken cancellationToken) =>
        services.GetRequiredService<IAdminSharedService>().GetSettings(cancellationToken);

    /// <summary>The merchant's rating breakdown.</summary>
    public Task<RatingSummary> Rating(Guid id, CancellationToken cancellationToken) =>
        services.GetRequiredService<IRatingSharedService>().GetMerchantRating(id, cancellationToken);

    /// <summary>The minimum level is 2 when the service demands Level 2 (PRD §6.1).</summary>
    private static MerchantService ToService(CatalogService s) => new()
    {
        Id = s.Id,
        Name = s.Name,
        Published = s.Published,
        MinLevel = s.RequiresLevel2 ? 2 : s.RequiredLevel,
        WomenProvidersOnly = s.WomenProvidersOnly,
    };

    private static async Task Codes(Func<Task> call)
    {
        try
        {
            await call();
        }
        catch (DomainException error) when (error.Reason == IdentityErrors.RateLimited)
        {
            throw new DomainException(MerchantReasons.CodeRateLimited, error);
        }
        catch (DomainException error) when (RejectedCodes.Contains(error.Reason))
        {
            throw new DomainException(MerchantReasons.CodeRejected, error);
        }
    }
}
