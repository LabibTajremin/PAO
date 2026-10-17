using PAO.Lib.Events;

namespace PAO.Lib.Areas.Verification;

/// <summary>Names of the events the Verification area publishes.</summary>
public static class VerificationEvents
{
    public const string ProviderLevelChanged = "verification.ProviderLevelChanged";
    public const string DocumentApproved = "verification.DocumentApproved";
    public const string DocumentRejected = "verification.DocumentRejected";
    public const string DocumentExpired = "verification.DocumentExpired";
    public const string DocumentExpiring = "verification.DocumentExpiring";
    public const string Level2SessionScheduled = "verification.Level2SessionScheduled";
    public const string Level2ResultRecorded = "verification.Level2ResultRecorded";
}

/// <summary>A merchant's verification level changed.</summary>
public sealed record ProviderLevelChanged : IDomainEvent
{
    public string Name { get; } = VerificationEvents.ProviderLevelChanged;
    public required Guid ProviderId { get; init; }
    public required int From { get; init; }
    public required int To { get; init; }
    public required string Reason { get; init; }
}

/// <summary>A reviewer approved an item.</summary>
public sealed record DocumentApproved : IDomainEvent
{
    public string Name { get; } = VerificationEvents.DocumentApproved;
    public required Guid ProviderId { get; init; }
    public required string Item { get; init; }
    public Guid? ActorId { get; init; }
}

/// <summary>A reviewer rejected an item.</summary>
public sealed record DocumentRejected : IDomainEvent
{
    public string Name { get; } = VerificationEvents.DocumentRejected;
    public required Guid ProviderId { get; init; }
    public required string Item { get; init; }
    public required string Reason { get; init; }
    public Guid? ActorId { get; init; }
}

/// <summary>An item's document expired.</summary>
public sealed record DocumentExpired : IDomainEvent
{
    public string Name { get; } = VerificationEvents.DocumentExpired;
    public required Guid ProviderId { get; init; }
    public required string Item { get; init; }
}

/// <summary>An item's document expires soon (P-11).</summary>
public sealed record DocumentExpiring : IDomainEvent
{
    public string Name { get; } = VerificationEvents.DocumentExpiring;
    public required Guid ProviderId { get; init; }
    public required string Item { get; init; }
    public required int DaysLeft { get; init; }
}

/// <summary>A Level 2 session was booked.</summary>
public sealed record Level2SessionScheduled : IDomainEvent
{
    public string Name { get; } = VerificationEvents.Level2SessionScheduled;
    public required Guid ProviderId { get; init; }
    public required Guid SessionId { get; init; }
    public required string ScheduledAt { get; init; }
    public required string Location { get; init; }
}

/// <summary>A Level 2 session's result was recorded.</summary>
public sealed record Level2ResultRecorded : IDomainEvent
{
    public string Name { get; } = VerificationEvents.Level2ResultRecorded;
    public required Guid ProviderId { get; init; }
    public required Guid SessionId { get; init; }
    public required string Result { get; init; }
    public Guid? ActorId { get; init; }
}
