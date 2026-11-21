using System.Text.Json.Serialization;
using PAO.Lib.Common;

namespace PAO.Lib.Areas.Merchant;

/// <summary>The `ProviderProfile` the partner app shows (M28).</summary>
public sealed record MerchantProfileView
{
    /// <summary>The id.</summary>
    public required Guid Id { get; init; }
    /// <summary>The full name.</summary>
    public required string Name { get; init; }
    /// <summary>The account phone.</summary>
    public required string Phone { get; init; }
    /// <summary>A short-lived photo URL; absent without a photo.</summary>
    [JsonIgnore(Condition = JsonIgnoreCondition.WhenWritingNull)]
    public string? PhotoUrl { get; init; }
    /// <summary>The bio.</summary>
    public required string Bio { get; init; }
    /// <summary>The account status.</summary>
    public required string Status { get; init; }
    /// <summary>The verification level.</summary>
    public required int Level { get; init; }
    /// <summary>The customer-facing badge.</summary>
    public required string Badge { get; init; }
    /// <summary>Whether the merchant is online.</summary>
    public required bool Online { get; init; }
    /// <summary>The language.</summary>
    public required string Language { get; init; }
    /// <summary>The services offered.</summary>
    public required IReadOnlyList<ServiceRefView> Services { get; init; }
    /// <summary>Years of experience.</summary>
    public required int ExperienceYears { get; init; }
    /// <summary>The home base; absent before the area step.</summary>
    [JsonIgnore(Condition = JsonIgnoreCondition.WhenWritingNull)]
    public GeoPoint? HomeBase { get; init; }
    /// <summary>The working radius; absent before the area step.</summary>
    [JsonIgnore(Condition = JsonIgnoreCondition.WhenWritingNull)]
    public int? WorkingRadiusM { get; init; }
    /// <summary>Whether a quality threshold flagged them.</summary>
    public required bool FlaggedForReview { get; init; }
}

/// <summary>A `RatingBreakdown`: average, count and reviews per star value "1".."5".</summary>
public sealed record RatingBreakdownView
{
    /// <summary>The average.</summary>
    public required double Average { get; init; }
    /// <summary>The count.</summary>
    public required int Count { get; init; }
    /// <summary>Reviews per star value.</summary>
    public required IReadOnlyDictionary<string, int> Distribution { get; init; }
}

/// <summary>The `ProviderPublicProfile` customers see (C11): never documents or contacts.</summary>
public sealed record MerchantPublicProfileView
{
    /// <summary>The id.</summary>
    public required Guid Id { get; init; }
    /// <summary>The full name.</summary>
    public required string Name { get; init; }
    /// <summary>A short-lived photo URL; absent without a photo.</summary>
    [JsonIgnore(Condition = JsonIgnoreCondition.WhenWritingNull)]
    public string? PhotoUrl { get; init; }
    /// <summary>The badge.</summary>
    public required string Badge { get; init; }
    /// <summary>The level.</summary>
    public required int Level { get; init; }
    /// <summary>The bio.</summary>
    public required string Bio { get; init; }
    /// <summary>Years of experience.</summary>
    public required int ExperienceYears { get; init; }
    /// <summary>The services offered.</summary>
    public required IReadOnlyList<ServiceRefView> Services { get; init; }
    /// <summary>The rating.</summary>
    public required RatingBreakdownView Rating { get; init; }
    /// <summary>Completed jobs.</summary>
    public required int CompletedJobs { get; init; }
    /// <summary>When the merchant joined, ISO 8601.</summary>
    public required string MemberSince { get; init; }
}

/// <summary>The `PresenceState` with the heartbeat interval the app keeps.</summary>
public sealed record PresenceStateView
{
    /// <summary>Whether the merchant is online.</summary>
    public required bool Online { get; init; }
    /// <summary>Seconds between heartbeats.</summary>
    public required int HeartbeatIntervalSeconds { get; init; }
}
