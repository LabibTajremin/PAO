using FluentValidation;
using PAO.Core.Areas.Rating.Repositories;
using PAO.Infrastructure.Http;
using PAO.Lib.Areas.Merchant;
using PAO.Lib.Areas.Rating;
using PAO.Lib.Mapping;
using PAO.Lib.Mediator;

namespace PAO.Core.Areas.Rating.Features.Reviews.Queries;

/// <summary>Customers' reviews of a provider, newest first (C42, M30).</summary>
public sealed record ListProviderReviews(Guid ProviderId, string? Cursor, int? Limit) : IQuery<ReviewListView>;

/// <summary>The provider's own rating breakdown (M30).</summary>
public sealed record GetMyRating(Guid ProviderId) : IQuery<RatingBreakdownView>;

/// <summary>Checks <see cref="ListProviderReviews"/>.</summary>
public sealed class ListProviderReviewsValidator : AbstractValidator<ListProviderReviews>
{
    /// <summary>The spec has checked the formats.</summary>
    public ListProviderReviewsValidator() => RuleFor(r => r.ProviderId).NotNull();
}

/// <summary>Checks <see cref="GetMyRating"/>.</summary>
public sealed class GetMyRatingValidator : AbstractValidator<GetMyRating>
{
    /// <summary>The caller.</summary>
    public GetMyRatingValidator() => RuleFor(r => r.ProviderId).NotNull();
}

/// <summary>Answers <see cref="ListProviderReviews"/>; one look-ahead row tells whether another page follows.</summary>
public sealed class ListProviderReviewsHandler(RatingRepository repository, IMapper mapper) : IRequestHandler<ListProviderReviews, ReviewListView>
{
    /// <inheritdoc />
    public async Task<ReviewListView> Handle(ListProviderReviews request, CancellationToken cancellationToken)
    {
        var cursor = Cursor.Decode(request.Cursor);
        var size = Cursor.PageSize(request.Limit);
        DateTimeOffset? at = cursor is null ? null : DateTimeOffset.Parse(cursor.CreatedAt, System.Globalization.CultureInfo.InvariantCulture).ToUniversalTime();
        var rows = await repository.Reviews(request.ProviderId, ReviewRole.Customer, at, cursor is null ? null : Guid.Parse(cursor.Id), size + 1, cancellationToken);
        var items = rows.Take(size).ToList();
        var next = rows.Count > size
            ? new Cursor(items[^1].CreatedAt.ToUniversalTime().ToString("O", System.Globalization.CultureInfo.InvariantCulture), items[^1].Id.ToString()).Encode()
            : null;
        return new ReviewListView { Items = mapper.MapAll<Review, ReviewView>(items), NextCursor = next };
    }
}

/// <summary>Answers <see cref="GetMyRating"/>; zero values when unrated.</summary>
public sealed class GetMyRatingHandler(RatingRepository repository, IMapper mapper) : IRequestHandler<GetMyRating, RatingBreakdownView>
{
    /// <inheritdoc />
    public async Task<RatingBreakdownView> Handle(GetMyRating request, CancellationToken cancellationToken)
    {
        var all = await repository.Aggregates(ReviewRole.Provider, [request.ProviderId], cancellationToken);
        return mapper.Map<Aggregate, RatingBreakdownView>(all.GetValueOrDefault(request.ProviderId) ?? Aggregate.Unrated);
    }
}
