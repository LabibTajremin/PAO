using PAO.Lib.Events;

namespace PAO.Lib.Areas.Rating;

/// <summary>A rating aggregate; zero values when unrated.</summary>
public sealed record RatingSummary
{
    public required double Average { get; init; }
    public required int Count { get; init; }

    /// <summary>Counts of 1 to 5 stars, in that order.</summary>
    public required IReadOnlyList<int> Distribution { get; init; }
}

/// <summary>Names of the events the Rating area publishes.</summary>
public static class RatingEvents
{
    public const string ReviewSubmitted = "rating.ReviewSubmitted";
}

/// <summary>A party reviewed the other after a job.</summary>
public sealed record ReviewSubmitted : IDomainEvent
{
    public string Name { get; } = RatingEvents.ReviewSubmitted;
    public required Guid ReviewId { get; init; }
    public required Guid BookingId { get; init; }
    public required Guid AuthorId { get; init; }
    public required Guid SubjectId { get; init; }
    public required string SubjectRole { get; init; }
    public required int Stars { get; init; }
    public required double NewAverage { get; init; }
    public required int NewCount { get; init; }
}
