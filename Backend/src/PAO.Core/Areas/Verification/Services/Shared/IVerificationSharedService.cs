using PAO.Lib.Areas.Verification;

namespace PAO.Core.Areas.Verification.Services.Shared;

/// <summary>
/// What other areas may ask of the Verification area; the only way they reach it (PRD §9.3
/// rule 1, enforced by the architecture tests).
/// </summary>
public interface IVerificationSharedService
{
    /// <summary>Returns the merchant's verification level (0 when never verified).</summary>
    Task<int> GetLevel(Guid merchantId, CancellationToken cancellationToken);

    /// <summary>Returns levels for many merchants at once, keyed by merchant id, for search ranking (one query, no N+1).</summary>
    Task<IReadOnlyDictionary<Guid, int>> GetLevels(IReadOnlyCollection<Guid> merchantIds, CancellationToken cancellationToken);

    /// <summary>Reports whether the merchant may receive bookings for the service: Level at least the service's required level (Level 2 when flagged), no expired document and not blocked (PRD §6.1, §6.4). A null service checks any service.</summary>
    Task<bool> CanReceiveBookings(Guid merchantId, Guid? serviceId, CancellationToken cancellationToken);

    /// <summary>Returns the merchant's verification items sorted by type (A-05).</summary>
    Task<IReadOnlyList<VerificationItem>> GetItems(Guid merchantId, CancellationToken cancellationToken);

    /// <summary>Counts submitted merchants with an item awaiting review (A-09).</summary>
    Task<int> CountPendingReviews(CancellationToken cancellationToken);
}
