using PAO.Lib.Areas.Merchant;

namespace PAO.Core.Areas.Merchant.Services;

/// <summary>Who may go online, how merchants are labelled and how search ranks them (PRD §5, §6.1).</summary>
public static class MerchantRules
{
    /// <summary>How often an online app reports its position, in seconds.</summary>
    public const int HeartbeatEverySeconds = 30;

    /// <summary>
    /// Why presence may not be switched on, or null for an active, verified merchant with a
    /// service area (PRD §6.1).
    /// </summary>
    public static string? CannotGoOnline(StoredMerchant m)
    {
        if (m.AccountStatus != "active" || m.Level < 1)
        {
            return MerchantReasons.NotVerified;
        }
        return m.HomeBase is null || m.ServiceIds.Count == 0 ? MerchantReasons.NoServiceArea : null;
    }

    /// <summary>The customer-facing label of a level (PRD §6.1).</summary>
    public static string Badge(int level) => level switch
    {
        >= 2 => "verified_pro",
        1 => "verified",
        _ => "none",
    };

    /// <summary>
    /// Orders candidates Level 2 first, then by distance or rating; ties fall back to
    /// distance. The sort is stable, so equal candidates keep their order.
    /// </summary>
    public static IReadOnlyList<MerchantCandidate> Rank(IEnumerable<MerchantCandidate> list, bool byRating)
    {
        var pro = list.OrderByDescending(c => c.Level >= 2);
        return byRating
            ? [.. pro.ThenByDescending(c => c.Rating).ThenBy(c => c.DistanceM)]
            : [.. pro.ThenBy(c => c.DistanceM)];
    }

    /// <summary>
    /// Keeps candidates within their own working radius and, for women-only services, women
    /// merchants (D11), with their distance from the presence index.
    /// </summary>
    public static IEnumerable<MerchantCandidate> Eligible(
        IEnumerable<MerchantCandidate> rows, IReadOnlyDictionary<Guid, double> distances, bool womenOnly) =>
        rows.Select(c => c with { DistanceM = distances.GetValueOrDefault(c.Id) })
            .Where(c => c.DistanceM <= c.WorkingRadiusM && (!womenOnly || c.Gender == Gender.Female));
}
