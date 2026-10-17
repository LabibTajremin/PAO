using PAO.Lib.Events;

namespace PAO.Lib.Areas.Merchant;

/// <summary>Filters for the admin merchant list (A-05), newest first.</summary>
public sealed record MerchantQuery
{
    public Guid? Id { get; init; }
    public required string Text { get; init; }
    public required string Status { get; init; }
    public int? Level { get; init; }
    public bool? Flagged { get; init; }
    public DateTimeOffset? AfterAt { get; init; }
    public Guid? AfterId { get; init; }
    public required int Limit { get; init; }
}

/// <summary>A row of the admin merchant list.</summary>
public sealed record MerchantRecord
{
    public required Guid Id { get; init; }
    public required string Name { get; init; }
    public required string Phone { get; init; }
    public required string Status { get; init; }
    public required int Level { get; init; }
    public required IReadOnlyList<Guid> ServiceIds { get; init; }
    public required double Rating { get; init; }
    public required int RatingCount { get; init; }
    public required int CompletedJobs { get; init; }
    public required bool Flagged { get; init; }
    public required string FlagReason { get; init; }
    public required bool Online { get; init; }
    public required DateTimeOffset CreatedAt { get; init; }
}

/// <summary>Names of the events the Merchant area publishes; the `provider.` prefix is kept.</summary>
public static class MerchantEvents
{
    public const string EnrolmentStepSaved = "provider.EnrolmentStepSaved";
    public const string ProviderFlaggedForReview = "provider.ProviderFlaggedForReview";
    public const string ProviderWentOffline = "provider.ProviderWentOffline";
}

/// <summary>A merchant saved an enrolment step.</summary>
public sealed record EnrolmentStepSaved : IDomainEvent
{
    public string Name { get; } = MerchantEvents.EnrolmentStepSaved;
    public required Guid ProviderId { get; init; }
    public required string Step { get; init; }
}

/// <summary>A merchant crossed a quality threshold (D13).</summary>
public sealed record ProviderFlaggedForReview : IDomainEvent
{
    public string Name { get; } = MerchantEvents.ProviderFlaggedForReview;
    public required Guid ProviderId { get; init; }
    public required string Reason { get; init; }
}

/// <summary>A merchant left presence, by choice or forced.</summary>
public sealed record ProviderWentOffline : IDomainEvent
{
    public string Name { get; } = MerchantEvents.ProviderWentOffline;
    public required Guid ProviderId { get; init; }
    public required string Reason { get; init; }
}
