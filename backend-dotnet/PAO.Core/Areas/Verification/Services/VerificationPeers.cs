using PAO.Core.Areas.Admin.Services.Shared;
using PAO.Core.Areas.Catalog.Services.Shared;
using PAO.Core.Areas.Media.Services.Shared;
using PAO.Core.Areas.Merchant.Services.Shared;
using PAO.Lib.Areas.Catalog;
using PAO.Lib.Areas.Media;
using PAO.Lib.Areas.Merchant;
using PAO.Lib.Areas.Verification;
using PAO.Lib.Errors;

namespace PAO.Core.Areas.Verification.Services;

/// <summary>A service as Verification sees it, with the level it requires (PRD §6.1).</summary>
public sealed record ServiceLevel(CatalogService Service, int MinLevel);

/// <summary>The admin-editable verification settings.</summary>
public sealed record VerificationSettings(TimeSpan PoliceClearanceValidity, TimeSpan Level2CoolingOff, TimeSpan DocumentRetention);

/// <summary>
/// Reaches Merchant, Media, Catalog and Admin through their shared services, resolved on first
/// use: Merchant and Verification depend on each other, and Merchant and Admin are ported in
/// parallel, so nothing is resolved until a use case needs it.
/// </summary>
public sealed class VerificationPeers(IServiceProvider services)
{
    // A host without the Merchant area (it is ported in parallel) knows no merchant.
    private IMerchantSharedService Merchants =>
        services.GetService<IMerchantSharedService>() ?? throw new DomainException(VerificationReasons.NotFound);

    private IMediaSharedService Media => services.GetRequiredService<IMediaSharedService>();

    /// <summary>The merchant's profile; throws `verification.provider_not_found` for an unknown one.</summary>
    public Task<MerchantProfile> Merchant(Guid id, CancellationToken cancellationToken) =>
        Translated(() => Merchants.GetMerchant(id, cancellationToken), MerchantErrors.NotFound, VerificationReasons.NotFound);

    /// <summary>The profiles of `ids` that exist, in one call to the Merchant contract.</summary>
    public Task<IReadOnlyDictionary<Guid, MerchantProfile>> MerchantsById(IReadOnlyCollection<Guid> ids, CancellationToken cancellationToken) =>
        Merchants.GetMerchants(ids, cancellationToken);

    /// <summary>Marks a document step done in the wizard.</summary>
    public Task<EnrolmentStatus> MarkStepDone(Guid id, string step, CancellationToken cancellationToken) =>
        Merchants.MarkStepDone(id, step, cancellationToken);

    /// <summary>Marks the enrolment submitted; throws `verification.enrolment_pending` while required steps are open.</summary>
    public Task MarkSubmitted(Guid id, CancellationToken cancellationToken) =>
        Translated(async () => { await Merchants.MarkSubmitted(id, cancellationToken); return true; }, MerchantErrors.EnrolmentIncomplete, VerificationReasons.EnrolmentPending);

    /// <summary>
    /// Checks the upload is the owner's confirmed file of an allowed purpose and spares it from
    /// the orphan purge; throws `verification.bad_document` otherwise.
    /// </summary>
    public async Task Attach(Guid owner, Guid mediaId, IReadOnlyCollection<string> purposes, CancellationToken cancellationToken)
    {
        MediaObject? found;
        try
        {
            found = await Media.GetObject(mediaId, cancellationToken);
        }
        catch (DomainException error) when (error.Reason == MediaErrors.NotFound)
        {
            found = null;
        }
        if (found is null || found.OwnerId != owner || !found.Confirmed || !purposes.Contains(found.Purpose))
        {
            throw new DomainException(VerificationReasons.BadDocument);
        }
        await Media.MarkAttached(mediaId, cancellationToken);
    }

    /// <summary>Deletes every file the account uploaded.</summary>
    public Task DeleteOwnedFiles(Guid owner, CancellationToken cancellationToken) => Media.DeleteOwnerFiles(owner, cancellationToken);

    /// <summary>Deletes one file; an already deleted one is not an error, so a retried purge goes on.</summary>
    public async Task DeleteFile(Guid mediaId, CancellationToken cancellationToken)
    {
        try
        {
            await Media.Delete(mediaId, cancellationToken);
        }
        catch (DomainException error) when (error.Reason == MediaErrors.NotFound)
        {
            // Deleted by an earlier, interrupted purge.
        }
    }

    /// <summary>A service and the level it requires (2 when flagged); an unknown one throws `verification.invalid`.</summary>
    public async Task<ServiceLevel> Service(Guid id, CancellationToken cancellationToken)
    {
        var s = await Translated(() => services.GetRequiredService<ICatalogSharedService>().GetService(id, cancellationToken), CatalogErrors.ServiceNotFound, VerificationReasons.Invalid);
        return new ServiceLevel(s, s.RequiresLevel2 ? 2 : s.RequiredLevel);
    }

    /// <summary>Every published service, so a page of the queue resolves its services with one call.</summary>
    public Task<IReadOnlyList<CatalogService>> Services(CancellationToken cancellationToken) =>
        services.GetRequiredService<ICatalogSharedService>().ListServices(cancellationToken);

    /// <summary>The defaults of `verification.police_clearance_validity_days`, `verification.level2_cooling_off_days` and `documents.retention_days`.</summary>
    public static readonly VerificationSettings Defaults = new(TimeSpan.FromDays(365), TimeSpan.FromDays(14), TimeSpan.FromDays(365));

    /// <summary>The verification rules from the platform settings (A-10).</summary>
    public async Task<VerificationSettings> Settings(CancellationToken cancellationToken)
    {
        // Until the Admin area is ported (P17), hosts without it use the defaults the admin
        // settings table starts with: 365, 14 and 365 days.
        if (services.GetService<IAdminSharedService>() is not { } admin)
        {
            return Defaults;
        }
        var s = await admin.GetSettings(cancellationToken);
        return new VerificationSettings(
            TimeSpan.FromMilliseconds(s.PoliceClearanceValidityMs), TimeSpan.FromMilliseconds(s.Level2CoolingOffMs), TimeSpan.FromMilliseconds(s.DocumentRetentionMs));
    }

    private static async Task<T> Translated<T>(Func<Task<T>> call, string from, string to)
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
