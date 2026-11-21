using PAO.Lib.Events;

namespace PAO.Lib.Areas.Rating;

/// <summary>A rating aggregate; zero values when unrated.</summary>
public sealed record RatingSummary
{
    /// <summary>The average.</summary>
    public required double Average { get; init; }
    /// <summary>The count.</summary>
    public required int Count { get; init; }

    /// <summary>Counts of 1 to 5 stars, in that order.</summary>
    public required IReadOnlyList<int> Distribution { get; init; }
}

/// <summary>Names of the events the Rating area publishes.</summary>
public static class RatingEvents
{
    /// <summary>The `"rating.ReviewSubmitted"` value.</summary>
    public const string ReviewSubmitted = "rating.ReviewSubmitted";
}

/// <summary>A party reviewed the other after a job.</summary>
public sealed record ReviewSubmitted : IDomainEvent
{
    /// <summary>The name.</summary>
    public string Name { get; } = RatingEvents.ReviewSubmitted;
    /// <summary>The review id.</summary>
    public required Guid ReviewId { get; init; }
    /// <summary>The booking id.</summary>
    public required Guid BookingId { get; init; }
    /// <summary>The author id.</summary>
    public required Guid AuthorId { get; init; }
    /// <summary>The subject id.</summary>
    public required Guid SubjectId { get; init; }
    /// <summary>The subject role.</summary>
    public required string SubjectRole { get; init; }
    /// <summary>The stars.</summary>
    public required int Stars { get; init; }
    /// <summary>The new average.</summary>
    public required double NewAverage { get; init; }
    /// <summary>The new count.</summary>
    public required int NewCount { get; init; }
}
