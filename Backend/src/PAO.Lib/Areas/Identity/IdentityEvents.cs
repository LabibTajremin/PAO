using PAO.Lib.Events;

namespace PAO.Lib.Areas.Identity;

/// <summary>Names of the events the Identity area publishes.</summary>
public static class IdentityEvents
{
    /// <summary>The `"identity.AccountCreated"` value.</summary>
    public const string AccountCreated = "identity.AccountCreated";
    /// <summary>The `"identity.RoleGranted"` value.</summary>
    public const string RoleGranted = "identity.RoleGranted";
    /// <summary>The `"identity.AccountStatusChanged"` value.</summary>
    public const string AccountStatusChanged = "identity.AccountStatusChanged";
    /// <summary>The `"identity.AccountDeleted"` value.</summary>
    public const string AccountDeleted = "identity.AccountDeleted";
}

/// <summary>A new account signed up with a role.</summary>
public sealed record AccountCreated : IDomainEvent
{
    /// <summary>The name.</summary>
    public string Name { get; } = IdentityEvents.AccountCreated;
    /// <summary>The account id.</summary>
    public required Guid AccountId { get; init; }
    /// <summary>The phone.</summary>
    public required string Phone { get; init; }
    /// <summary>The role.</summary>
    public required string Role { get; init; }
}

/// <summary>An account received another role.</summary>
public sealed record RoleGranted : IDomainEvent
{
    /// <summary>The name.</summary>
    public string Name { get; } = IdentityEvents.RoleGranted;
    /// <summary>The account id.</summary>
    public required Guid AccountId { get; init; }
    /// <summary>The role.</summary>
    public required string Role { get; init; }
}

/// <summary>An account was suspended, banned or reinstated.</summary>
public sealed record AccountStatusChanged : IDomainEvent
{
    /// <summary>The name.</summary>
    public string Name { get; } = IdentityEvents.AccountStatusChanged;
    /// <summary>The account id.</summary>
    public required Guid AccountId { get; init; }
    /// <summary>The from.</summary>
    public required string From { get; init; }
    /// <summary>The to.</summary>
    public required string To { get; init; }
    /// <summary>The reason.</summary>
    public required string Reason { get; init; }
    /// <summary>The actor id.</summary>
    public Guid? ActorId { get; init; }
    /// <summary>The roles.</summary>
    public required IReadOnlyList<string> Roles { get; init; }
}

/// <summary>An account was closed and its personal data erased.</summary>
public sealed record AccountDeleted : IDomainEvent
{
    /// <summary>The name.</summary>
    public string Name { get; } = IdentityEvents.AccountDeleted;
    /// <summary>The account id.</summary>
    public required Guid AccountId { get; init; }
}
