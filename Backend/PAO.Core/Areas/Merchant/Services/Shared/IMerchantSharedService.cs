using PAO.Lib.Areas.Merchant;

namespace PAO.Core.Areas.Merchant.Services.Shared;

/// <summary>
/// What other areas may ask of the Merchant area; the only way they reach it (PRD §9.3
/// rule 1, enforced by the architecture tests).
/// </summary>
public interface IMerchantSharedService
{
    /// <summary>Returns a merchant's profile, or throws `provider.not_found`.</summary>
    Task<MerchantProfile> GetMerchant(Guid merchantId, CancellationToken cancellationToken);

    /// <summary>Returns the profiles of `merchantIds` that exist, keyed by id, in one round of queries (no N+1).</summary>
    Task<IReadOnlyDictionary<Guid, MerchantProfile>> GetMerchants(IReadOnlyCollection<Guid> merchantIds, CancellationToken cancellationToken);

    /// <summary>Reports whether the merchant is online right now.</summary>
    Task<bool> IsAvailable(Guid merchantId, CancellationToken cancellationToken);

    /// <summary>Returns verified, online merchants registered for the service within its radius: Level 2 first, then by the requested sort (PRD §5, D11).</summary>
    Task<IReadOnlyList<NearbyMerchant>> FindNearby(NearbyQuery query, CancellationToken cancellationToken);

    /// <summary>Returns the wizard progress; a merchant who has saved nothing yet has every step open.</summary>
    Task<EnrolmentStatus> Enrolment(Guid merchantId, CancellationToken cancellationToken);

    /// <summary>Records a document step saved by Verification.</summary>
    Task<EnrolmentStatus> MarkStepDone(Guid merchantId, string step, CancellationToken cancellationToken);

    /// <summary>Records that the merchant sent the enrolment for review.</summary>
    Task MarkSubmitted(Guid merchantId, CancellationToken cancellationToken);

    /// <summary>Removes the merchant from presence, e.g. after a ban or an expired document.</summary>
    Task ForceOffline(Guid merchantId, CancellationToken cancellationToken);

    /// <summary>Lists merchants for the admin console, newest first (A-05).</summary>
    Task<IReadOnlyList<MerchantRecord>> SearchMerchants(MerchantQuery query, CancellationToken cancellationToken);
}
