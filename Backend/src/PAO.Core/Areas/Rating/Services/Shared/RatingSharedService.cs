using PAO.Core.Areas.Rating.Repositories;
using PAO.Lib.Areas.Rating;
using PAO.Lib.Mapping;

namespace PAO.Core.Areas.Rating.Services.Shared;

/// <summary>The Rating contract for the other areas.</summary>
public sealed class RatingSharedService(RatingRepository repository, IMapper mapper) : IRatingSharedService
{
    /// <inheritdoc />
    public Task<RatingSummary> GetMerchantRating(Guid merchantId, CancellationToken cancellationToken) =>
        One(ReviewRole.Provider, merchantId, cancellationToken);

    /// <inheritdoc />
    public async Task<IReadOnlyDictionary<Guid, RatingSummary>> GetMerchantRatings(IReadOnlyCollection<Guid> merchantIds, CancellationToken cancellationToken) =>
        (await repository.Aggregates(ReviewRole.Provider, merchantIds, cancellationToken))
            .ToDictionary(kv => kv.Key, kv => mapper.Map<Aggregate, RatingSummary>(kv.Value));

    /// <inheritdoc />
    public Task<RatingSummary> GetCustomerRating(Guid customerId, CancellationToken cancellationToken) =>
        One(ReviewRole.Customer, customerId, cancellationToken);

    /// <inheritdoc />
    public Task<bool> HasReviewed(Guid bookingId, Guid authorId, CancellationToken cancellationToken) =>
        repository.HasReviewed(bookingId, authorId, cancellationToken);

    private async Task<RatingSummary> One(string role, Guid id, CancellationToken cancellationToken)
    {
        var all = await repository.Aggregates(role, [id], cancellationToken);
        return mapper.Map<Aggregate, RatingSummary>(all.GetValueOrDefault(id) ?? Aggregate.Unrated);
    }
}
