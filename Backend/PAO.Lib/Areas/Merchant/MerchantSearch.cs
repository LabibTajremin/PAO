using PAO.Lib.Events;

namespace PAO.Lib.Areas.Merchant;

/// <summary>Filters for the admin merchant list (A-05), newest first.</summary>
public sealed record MerchantQuery
{
    /// <summary>The id.</summary>
    public Guid? Id { get; init; }
    /// <summary>The text.</summary>
    public required string Text { get; init; }
    /// <summary>The status.</summary>
    public required string Status { get; init; }
    /// <summary>The level.</summary>
    public int? Level { get; init; }
    /// <summary>The flagged.</summary>
    public bool? Flagged { get; init; }
    /// <summary>The after at.</summary>
    public DateTimeOffset? AfterAt { get; init; }
    /// <summary>The after id.</summary>
    public Guid? AfterId { get; init; }
    /// <summary>The limit.</summary>
    public required int Limit { get; init; }
}

/// <summary>A row of the admin merchant list.</summary>
public sealed record MerchantRecord
{
    /// <summary>The id.</summary>
    public required Guid Id { get; init; }
    /// <summary>The name.</summary>
    public required string Name { get; init; }
    /// <summary>The phone.</summary>
    public required string Phone { get; init; }
    /// <summary>The status.</summary>
    public required string Status { get; init; }
    /// <summary>The level.</summary>
    public required int Level { get; init; }
    /// <summary>The service ids.</summary>
    public required IReadOnlyList<Guid> ServiceIds { get; init; }
    /// <summary>The rating.</summary>
    public required double Rating { get; init; }
    /// <summary>The rating count.</summary>
    public required int RatingCount { get; init; }
    /// <summary>The completed jobs.</summary>
    public required int CompletedJobs { get; init; }
    /// <summary>Whether flagged.</summary>
    public required bool Flagged { get; init; }
    /// <summary>The flag reason.</summary>
    public required string FlagReason { get; init; }
    /// <summary>Whether online.</summary>
    public required bool Online { get; init; }
    /// <summary>The created at.</summary>
    public required DateTimeOffset CreatedAt { get; init; }
}

/// <summary>Names of the events the Merchant area publishes; the `provider.` prefix is kept.</summary>
public static class MerchantEvents
{
    /// <summary>The `"provider.EnrolmentStepSaved"` value.</summary>
    public const string EnrolmentStepSaved = "provider.EnrolmentStepSaved";
    /// <summary>The `"provider.ProviderFlaggedForReview"` value.</summary>
    public const string ProviderFlaggedForReview = "provider.ProviderFlaggedForReview";
    /// <summary>The `"provider.ProviderWentOffline"` value.</summary>
    public const string ProviderWentOffline = "provider.ProviderWentOffline";
}

/// <summary>A merchant saved an enrolment step.</summary>
public sealed record EnrolmentStepSaved : IDomainEvent
{
    /// <summary>The name.</summary>
    public string Name { get; } = MerchantEvents.EnrolmentStepSaved;
    /// <summary>The provider id.</summary>
    public required Guid ProviderId { get; init; }
    /// <summary>The step.</summary>
    public required string Step { get; init; }
}

/// <summary>A merchant crossed a quality threshold (D13).</summary>
public sealed record ProviderFlaggedForReview : IDomainEvent
{
    /// <summary>The name.</summary>
    public string Name { get; } = MerchantEvents.ProviderFlaggedForReview;
    /// <summary>The provider id.</summary>
    public required Guid ProviderId { get; init; }
    /// <summary>The reason.</summary>
    public required string Reason { get; init; }
}

/// <summary>A merchant left presence, by choice or forced.</summary>
public sealed record ProviderWentOffline : IDomainEvent
{
    /// <summary>The name.</summary>
    public string Name { get; } = MerchantEvents.ProviderWentOffline;
    /// <summary>The provider id.</summary>
    public required Guid ProviderId { get; init; }
    /// <summary>The reason.</summary>
    public required string Reason { get; init; }
}
