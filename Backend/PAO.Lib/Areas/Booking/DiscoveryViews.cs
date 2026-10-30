using System.Text.Json.Serialization;
using PAO.Lib.Common;

namespace PAO.Lib.Areas.Booking;

/// <summary>The spec's `ProviderCard`.</summary>
public sealed record ProviderCardView
{
    /// <summary>The id.</summary>
    public required Guid Id { get; init; }
    /// <summary>The name.</summary>
    public required string Name { get; init; }
    /// <summary>The level.</summary>
    public required int Level { get; init; }
    /// <summary>The average rating.</summary>
    public required double Rating { get; init; }
    /// <summary>How many ratings.</summary>
    public required int RatingCount { get; init; }
    /// <summary>Completed jobs.</summary>
    public required int CompletedJobs { get; init; }
    /// <summary>Metres away.</summary>
    public required int DistanceM { get; init; }
    /// <summary>`verified` or `verified_pro`.</summary>
    public required string Badge { get; init; }
    /// <summary>A signed photo URL, when one could be signed.</summary>
    [JsonIgnore(Condition = JsonIgnoreCondition.WhenWritingNull)]
    public string? PhotoUrl { get; init; }
}

/// <summary>The spec's `PriceSummary`.</summary>
public sealed record PriceSummaryView
{
    /// <summary>The sub-service.</summary>
    public required Guid SubServiceId { get; init; }
    /// <summary>The quantity.</summary>
    public required int Quantity { get; init; }
    /// <summary>The unit price.</summary>
    public required long UnitPrice { get; init; }
    /// <summary>The total.</summary>
    public required long Total { get; init; }
}

/// <summary>The spec's `NearbyProviders`.</summary>
public sealed record NearbyProvidersView
{
    /// <summary>The providers.</summary>
    public required IReadOnlyList<ProviderCardView> Items { get; init; }
    /// <summary>The fixed price.</summary>
    public required PriceSummaryView PriceSummary { get; init; }
}

/// <summary>One day of the spec's `EarningsSummary`.</summary>
public sealed record EarningsBucketView
{
    /// <summary>The Dhaka date.</summary>
    public required string Date { get; init; }
    /// <summary>Jobs.</summary>
    public required int Jobs { get; init; }
    /// <summary>Earned.</summary>
    public required long Total { get; init; }
}

/// <summary>The spec's `EarningsSummary` (P-08).</summary>
public sealed record EarningsSummaryView
{
    /// <summary>`day`, `week` or `month`.</summary>
    public required string Period { get; init; }
    /// <summary>The first day.</summary>
    public required string From { get; init; }
    /// <summary>The last day.</summary>
    public required string To { get; init; }
    /// <summary>Earned.</summary>
    public required long Total { get; init; }
    /// <summary>Jobs.</summary>
    public required int Jobs { get; init; }
    /// <summary>Every day of the period.</summary>
    public required IReadOnlyList<EarningsBucketView> Buckets { get; init; }
}

/// <summary>The spec's `EarningsJob`.</summary>
public sealed record EarningsJobView
{
    /// <summary>The booking.</summary>
    public required Guid BookingId { get; init; }
    /// <summary>The number.</summary>
    public required string Number { get; init; }
    /// <summary>When completed.</summary>
    public required string CompletedAt { get; init; }
    /// <summary>The service name.</summary>
    public required Text ServiceName { get; init; }
    /// <summary>Earned.</summary>
    public required long Total { get; init; }
}

/// <summary>The spec's `EarningsJobList`.</summary>
public sealed record EarningsJobListView
{
    /// <summary>The jobs.</summary>
    public required IReadOnlyList<EarningsJobView> Items { get; init; }
    /// <summary>The cursor of the next page.</summary>
    [JsonIgnore(Condition = JsonIgnoreCondition.WhenWritingNull)]
    public string? NextCursor { get; init; }
}
