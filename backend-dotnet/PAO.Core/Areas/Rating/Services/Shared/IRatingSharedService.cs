using PAO.Lib.Areas.Rating;

namespace PAO.Core.Areas.Rating.Services.Shared;

/// <summary>
/// What other areas may ask of the Rating area; the only way they reach it (PRD §9.3
/// rule 1, enforced by the architecture tests).
/// </summary>
public interface IRatingSharedService
{
    /// <summary>Returns the merchant's aggregate (zero values when unrated).</summary>
    Task<RatingSummary> GetMerchantRating(Guid merchantId, CancellationToken cancellationToken);

    /// <summary>Returns aggregates for many merchants, keyed by merchant id, for search ranking (one query, no N+1).</summary>
    Task<IReadOnlyDictionary<Guid, RatingSummary>> GetMerchantRatings(IReadOnlyCollection<Guid> merchantIds, CancellationToken cancellationToken);

    /// <summary>Returns the aggregate merchants gave a customer (M16).</summary>
    Task<RatingSummary> GetCustomerRating(Guid customerId, CancellationToken cancellationToken);

    /// <summary>Reports whether the author already reviewed the booking.</summary>
    Task<bool> HasReviewed(Guid bookingId, Guid authorId, CancellationToken cancellationToken);
}
