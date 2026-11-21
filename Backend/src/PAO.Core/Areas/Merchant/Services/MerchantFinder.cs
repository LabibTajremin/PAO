using PAO.Core.Areas.Merchant.Repositories;
using PAO.Lib.Areas.Merchant;

namespace PAO.Core.Areas.Merchant.Services;

/// <summary>Finds merchants for customers and lists them for admins.</summary>
public sealed class MerchantFinder(MerchantRepository repository, IPresence presence, MerchantPeers peers)
{
    /// <summary>
    /// Online merchants who may take the service, within both the search radius and their
    /// own working radius, Level 2 first (PRD §5, D11).
    /// </summary>
    public async Task<IReadOnlyList<NearbyMerchant>> Nearby(NearbyQuery q, CancellationToken cancellationToken)
    {
        var service = await peers.Service(q.ServiceId, cancellationToken);
        var distances = await presence.Near(q.ServiceId, q.Point, q.RadiusM);
        if (distances.Count == 0)
        {
            return [];
        }
        var rows = await repository.Candidates([.. distances.Keys], Math.Max(1, service.MinLevel), cancellationToken);
        var eligible = MerchantRules.Eligible(rows, distances, q.WomenProvidersOnly || service.WomenProvidersOnly);
        var ranked = MerchantRules.Rank(eligible, q.Sort == SortOrder.Rating);
        return [.. (q.Limit > 0 ? ranked.Take(q.Limit) : ranked).Select(c => new NearbyMerchant
        {
            ProviderId = c.Id,
            Name = c.Name,
            PhotoMediaId = c.PhotoMediaId,
            Level = c.Level,
            Rating = c.Rating,
            RatingCount = c.RatingCount,
            CompletedJobs = c.CompletedJobs,
            DistanceM = c.DistanceM,
        })];
    }

    /// <summary>Merchants for the admin console with their live online flag, read in one round trip (A-05).</summary>
    public async Task<IReadOnlyList<MerchantRecord>> Search(MerchantQuery q, CancellationToken cancellationToken)
    {
        var rows = await repository.Search(q, cancellationToken);
        var online = await presence.OnlineAmong([.. rows.Select(r => r.Id)]);
        return [.. rows.Select(r => r with { Online = online.Contains(r.Id) })];
    }
}
