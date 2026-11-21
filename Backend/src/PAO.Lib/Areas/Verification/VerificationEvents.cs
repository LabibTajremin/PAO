using PAO.Lib.Events;

namespace PAO.Lib.Areas.Verification;

/// <summary>Names of the events the Verification area publishes.</summary>
public static class VerificationEvents
{
    /// <summary>The `"verification.ProviderLevelChanged"` value.</summary>
    public const string ProviderLevelChanged = "verification.ProviderLevelChanged";
    /// <summary>The `"verification.DocumentApproved"` value.</summary>
    public const string DocumentApproved = "verification.DocumentApproved";
    /// <summary>The `"verification.DocumentRejected"` value.</summary>
    public const string DocumentRejected = "verification.DocumentRejected";
    /// <summary>The `"verification.DocumentExpired"` value.</summary>
    public const string DocumentExpired = "verification.DocumentExpired";
    /// <summary>The `"verification.DocumentExpiring"` value.</summary>
    public const string DocumentExpiring = "verification.DocumentExpiring";
    /// <summary>The `"verification.Level2SessionScheduled"` value.</summary>
    public const string Level2SessionScheduled = "verification.Level2SessionScheduled";
    /// <summary>The `"verification.Level2ResultRecorded"` value.</summary>
    public const string Level2ResultRecorded = "verification.Level2ResultRecorded";
}

/// <summary>A merchant's verification level changed.</summary>
public sealed record ProviderLevelChanged : IDomainEvent
{
    /// <summary>The name.</summary>
    public string Name { get; } = VerificationEvents.ProviderLevelChanged;
    /// <summary>The provider id.</summary>
    public required Guid ProviderId { get; init; }
    /// <summary>The from.</summary>
    public required int From { get; init; }
    /// <summary>The to.</summary>
    public required int To { get; init; }
    /// <summary>The reason.</summary>
    public required string Reason { get; init; }
}

/// <summary>A reviewer approved an item.</summary>
public sealed record DocumentApproved : IDomainEvent
{
    /// <summary>The name.</summary>
    public string Name { get; } = VerificationEvents.DocumentApproved;
    /// <summary>The provider id.</summary>
    public required Guid ProviderId { get; init; }
    /// <summary>The item.</summary>
    public required string Item { get; init; }
    /// <summary>The actor id.</summary>
    public Guid? ActorId { get; init; }
}

/// <summary>A reviewer rejected an item.</summary>
public sealed record DocumentRejected : IDomainEvent
{
    /// <summary>The name.</summary>
    public string Name { get; } = VerificationEvents.DocumentRejected;
    /// <summary>The provider id.</summary>
    public required Guid ProviderId { get; init; }
    /// <summary>The item.</summary>
    public required string Item { get; init; }
    /// <summary>The reason.</summary>
    public required string Reason { get; init; }
    /// <summary>The actor id.</summary>
    public Guid? ActorId { get; init; }
}

/// <summary>An item's document expired.</summary>
public sealed record DocumentExpired : IDomainEvent
{
    /// <summary>The name.</summary>
    public string Name { get; } = VerificationEvents.DocumentExpired;
    /// <summary>The provider id.</summary>
    public required Guid ProviderId { get; init; }
    /// <summary>The item.</summary>
    public required string Item { get; init; }
}

/// <summary>An item's document expires soon (P-11).</summary>
public sealed record DocumentExpiring : IDomainEvent
{
    /// <summary>The name.</summary>
    public string Name { get; } = VerificationEvents.DocumentExpiring;
    /// <summary>The provider id.</summary>
    public required Guid ProviderId { get; init; }
    /// <summary>The item.</summary>
    public required string Item { get; init; }
    /// <summary>The days left.</summary>
    public required int DaysLeft { get; init; }
}

/// <summary>A Level 2 session was booked.</summary>
public sealed record Level2SessionScheduled : IDomainEvent
{
    /// <summary>The name.</summary>
    public string Name { get; } = VerificationEvents.Level2SessionScheduled;
    /// <summary>The provider id.</summary>
    public required Guid ProviderId { get; init; }
    /// <summary>The session id.</summary>
    public required Guid SessionId { get; init; }
    /// <summary>The scheduled at.</summary>
    public required string ScheduledAt { get; init; }
    /// <summary>The location.</summary>
    public required string Location { get; init; }
}

/// <summary>A Level 2 session's result was recorded.</summary>
public sealed record Level2ResultRecorded : IDomainEvent
{
    /// <summary>The name.</summary>
    public string Name { get; } = VerificationEvents.Level2ResultRecorded;
    /// <summary>The provider id.</summary>
    public required Guid ProviderId { get; init; }
    /// <summary>The session id.</summary>
    public required Guid SessionId { get; init; }
    /// <summary>The result.</summary>
    public required string Result { get; init; }
    /// <summary>The actor id.</summary>
    public Guid? ActorId { get; init; }
}
