using PAO.Core.Areas.Verification.Repositories;
using PAO.Lib.Areas.Verification;

namespace PAO.Core.Areas.Verification.Services.Shared;

/// <summary>The Verification contract for the other areas; Identity's getMyPermissions reads the merchant level here.</summary>
public sealed class VerificationSharedService(VerificationRepository repository, VerificationStates states, VerificationPeers peers) : IVerificationSharedService
{
    /// <inheritdoc />
    public Task<int> GetLevel(Guid merchantId, CancellationToken cancellationToken) => repository.Level(merchantId, cancellationToken);

    /// <inheritdoc />
    public Task<IReadOnlyDictionary<Guid, int>> GetLevels(IReadOnlyCollection<Guid> merchantIds, CancellationToken cancellationToken) =>
        repository.Levels(merchantIds, cancellationToken);

    /// <inheritdoc />
    public async Task<bool> CanReceiveBookings(Guid merchantId, Guid? serviceId, CancellationToken cancellationToken)
    {
        var st = await states.Load(merchantId, cancellationToken);
        var minLevel = serviceId is { } id ? (await peers.Service(id, cancellationToken)).MinLevel : 0;
        return VerificationRules.CanReceiveBookings(st, minLevel);
    }

    /// <inheritdoc />
    public async Task<IReadOnlyList<VerificationItem>> GetItems(Guid merchantId, CancellationToken cancellationToken)
    {
        var st = await states.Load(merchantId, cancellationToken);
        return [.. st.Items.Values.OrderBy(it => it.Type, StringComparer.Ordinal).Select(it => new VerificationItem
        {
            Type = it.Type,
            Status = it.Status,
            Reason = it.Reason,
            Required = ItemType.IsRequired(it.Type),
            DecidedAt = it.DecidedAt,
            ExpiresAt = it.ExpiresAt,
        })];
    }

    /// <inheritdoc />
    public Task<int> CountPendingReviews(CancellationToken cancellationToken) => repository.CountPendingReviews(cancellationToken);
}
