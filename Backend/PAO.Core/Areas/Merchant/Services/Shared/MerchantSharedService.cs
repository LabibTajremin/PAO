using PAO.Core.Areas.Merchant.Repositories;
using PAO.Lib.Areas.Merchant;
using PAO.Lib.Mapping;

namespace PAO.Core.Areas.Merchant.Services.Shared;

/// <summary>The Merchant contract for the other areas.</summary>
public sealed class MerchantSharedService(
    MerchantProfiles profiles, MerchantRepository repository, MerchantEnrolment enrolment, MerchantPresence presence, MerchantFinder finder, IMapper mapper) : IMerchantSharedService
{
    /// <inheritdoc />
    public async Task<MerchantProfile> GetMerchant(Guid merchantId, CancellationToken cancellationToken) =>
        mapper.Map<StoredMerchant, MerchantProfile>(await profiles.Get(merchantId, cancellationToken));

    /// <inheritdoc />
    public async Task<IReadOnlyDictionary<Guid, MerchantProfile>> GetMerchants(IReadOnlyCollection<Guid> merchantIds, CancellationToken cancellationToken) =>
        (await repository.GetMany(merchantIds, cancellationToken)).ToDictionary(m => m.Id, mapper.Map<StoredMerchant, MerchantProfile>);

    /// <inheritdoc />
    public Task<bool> IsAvailable(Guid merchantId, CancellationToken cancellationToken) => presence.IsAvailable(merchantId);

    /// <inheritdoc />
    public Task<IReadOnlyList<NearbyMerchant>> FindNearby(NearbyQuery query, CancellationToken cancellationToken) =>
        finder.Nearby(query, cancellationToken);

    /// <inheritdoc />
    public Task<EnrolmentStatus> Enrolment(Guid merchantId, CancellationToken cancellationToken) =>
        enrolment.Progress(merchantId, cancellationToken);

    /// <inheritdoc />
    public Task<EnrolmentStatus> MarkStepDone(Guid merchantId, string step, CancellationToken cancellationToken) =>
        enrolment.MarkStepDone(merchantId, step, cancellationToken);

    /// <inheritdoc />
    public Task MarkSubmitted(Guid merchantId, CancellationToken cancellationToken) => enrolment.MarkSubmitted(merchantId, cancellationToken);

    /// <inheritdoc />
    public Task ForceOffline(Guid merchantId, CancellationToken cancellationToken) => presence.GoOffline(merchantId, "forced", cancellationToken);

    /// <inheritdoc />
    public Task<IReadOnlyList<MerchantRecord>> SearchMerchants(MerchantQuery query, CancellationToken cancellationToken) =>
        finder.Search(query, cancellationToken);
}
