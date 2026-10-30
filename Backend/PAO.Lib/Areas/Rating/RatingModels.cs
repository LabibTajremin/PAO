using System.Text.Json.Serialization;
using PAO.EF.Rating;
using PAO.Lib.Common;
using PAO.Lib.Mapping;

namespace PAO.Lib.Areas.Rating;

/// <summary>Why a review was refused.</summary>
public static class RatingReasons
{
    /// <summary>The `"rating.not_allowed"` value.</summary>
    public const string NotAllowed = "rating.not_allowed";
    /// <summary>The `"rating.already_reviewed"` value.</summary>
    public const string AlreadyReviewed = "rating.already_reviewed";
    /// <summary>The `"rating.invalid"` value.</summary>
    public const string Invalid = "rating.invalid";
}

/// <summary>The two sides of a booking, as authors and subjects of reviews.</summary>
public static class ReviewRole
{
    /// <summary>The `"customer"` value.</summary>
    public const string Customer = "customer";
    /// <summary>The `"provider"` value.</summary>
    public const string Provider = "provider";

    /// <summary>The role of the person an author of `role` reviews.</summary>
    public static string SubjectOf(string role) => role == Customer ? Provider : Customer;
}

/// <summary>A completed booking; only these may be reviewed.</summary>
public sealed record Reviewable(Guid BookingId, Guid CustomerId, Guid ProviderId, string CustomerName, string ProviderName, Text ServiceName, DateTimeOffset CompletedAt);

/// <summary>One side's rating of the other.</summary>
public sealed record Review
{
    /// <summary>The id.</summary>
    public required Guid Id { get; init; }
    /// <summary>The booking.</summary>
    public required Guid BookingId { get; init; }
    /// <summary>The author.</summary>
    public required Guid AuthorId { get; init; }
    /// <summary>The author's role.</summary>
    public required string AuthorRole { get; init; }
    /// <summary>The author's first name.</summary>
    public required string AuthorName { get; init; }
    /// <summary>Who is reviewed.</summary>
    public required Guid SubjectId { get; init; }
    /// <summary>1 to 5.</summary>
    public required int Stars { get; init; }
    /// <summary>The tags.</summary>
    public required IReadOnlyList<string> Tags { get; init; }
    /// <summary>The trimmed comment.</summary>
    public required string Comment { get; init; }
    /// <summary>The service name.</summary>
    public required Text ServiceName { get; init; }
    /// <summary>When written.</summary>
    public required DateTimeOffset CreatedAt { get; init; }
}

/// <summary>Running review totals of a subject.</summary>
public sealed record Aggregate(int Count, long Sum, IReadOnlyList<int> Distribution)
{
    /// <summary>The aggregate of someone nobody has reviewed yet.</summary>
    public static readonly Aggregate Unrated = new(0, 0, [0, 0, 0, 0, 0]);

    /// <summary>The mean rounded half up to one decimal, 0 when unrated.</summary>
    public double Average => Count == 0 ? 0 : Math.Floor(((double)Sum / Count * 10) + 0.5) / 10;
}

/// <summary>The `ReviewInput` body.</summary>
public sealed record ReviewInput
{
    /// <summary>1 to 5.</summary>
    public int Stars { get; init; }
    /// <summary>Up to six distinct tags.</summary>
    public IReadOnlyList<string>? Tags { get; init; }
    /// <summary>Up to 500 characters.</summary>
    public string? Comment { get; init; }
}

/// <summary>The spec's `Review`; an empty comment is left out.</summary>
public sealed record ReviewView
{
    /// <summary>The id.</summary>
    public required Guid Id { get; init; }
    /// <summary>The booking.</summary>
    public required Guid BookingId { get; init; }
    /// <summary>The stars.</summary>
    public required int Stars { get; init; }
    /// <summary>The author's first name.</summary>
    public required string AuthorName { get; init; }
    /// <summary>When written.</summary>
    public required string CreatedAt { get; init; }
    /// <summary>The service name.</summary>
    public required Text ServiceName { get; init; }
    /// <summary>The tags.</summary>
    public required IReadOnlyList<string> Tags { get; init; }
    /// <summary>The comment.</summary>
    [JsonIgnore(Condition = JsonIgnoreCondition.WhenWritingNull)]
    public string? Comment { get; init; }
}

/// <summary>The spec's `ReviewList`.</summary>
public sealed record ReviewListView
{
    /// <summary>The reviews.</summary>
    public required IReadOnlyList<ReviewView> Items { get; init; }
    /// <summary>The cursor of the next page.</summary>
    [JsonIgnore(Condition = JsonIgnoreCondition.WhenWritingNull)]
    public string? NextCursor { get; init; }
}

/// <summary>The Rating area's maps.</summary>
public sealed class RatingMappingProfile : IMappingProfile
{
    /// <inheritdoc />
    public void Configure(MappingRegistry registry) => registry
        .Add<Review, ReviewView>((r, _) => new ReviewView
        {
            Id = r.Id,
            BookingId = r.BookingId,
            Stars = r.Stars,
            AuthorName = r.AuthorName,
            CreatedAt = IsoTime.Format(r.CreatedAt),
            ServiceName = r.ServiceName,
            Tags = r.Tags,
            Comment = r.Comment.Length == 0 ? null : r.Comment,
        })
        .Add<Aggregate, RatingSummary>((a, _) => new RatingSummary { Average = a.Average, Count = a.Count, Distribution = a.Distribution })
        .Add<Aggregate, Merchant.RatingBreakdownView>((a, _) => new Merchant.RatingBreakdownView
        {
            Average = a.Average,
            Count = a.Count,
            Distribution = a.Distribution.Select((n, i) => (n, i)).ToDictionary(x => (x.i + 1).ToString(System.Globalization.CultureInfo.InvariantCulture), x => x.n),
        })
        .Add<RatingAggregateRecord, Aggregate>((r, _) => new Aggregate(r.ReviewCount, r.StarSum, [r.Stars1, r.Stars2, r.Stars3, r.Stars4, r.Stars5]))
        .Add<ReviewRecord, Review>((r, _) => new Review
        {
            Id = r.Id,
            BookingId = r.BookingId,
            AuthorId = r.AuthorId,
            AuthorRole = r.AuthorRole,
            AuthorName = r.AuthorName,
            SubjectId = r.SubjectId,
            Stars = r.Stars,
            Tags = r.Tags,
            Comment = r.Comment,
            ServiceName = new Text { En = r.ServiceNameEn, Bn = r.ServiceNameBn },
            CreatedAt = r.CreatedAt,
        });
}
