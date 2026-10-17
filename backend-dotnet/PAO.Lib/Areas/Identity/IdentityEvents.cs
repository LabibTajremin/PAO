using PAO.Lib.Events;

namespace PAO.Lib.Areas.Identity;

/// <summary>Names of the events the Identity area publishes.</summary>
public static class IdentityEvents
{
    public const string AccountCreated = "identity.AccountCreated";
    public const string RoleGranted = "identity.RoleGranted";
    public const string AccountStatusChanged = "identity.AccountStatusChanged";
    public const string AccountDeleted = "identity.AccountDeleted";
}

/// <summary>A new account signed up with a role.</summary>
public sealed record AccountCreated : IDomainEvent
{
    public string Name { get; } = IdentityEvents.AccountCreated;
    public required Guid AccountId { get; init; }
    public required string Phone { get; init; }
    public required string Role { get; init; }
}

/// <summary>An account received another role.</summary>
public sealed record RoleGranted : IDomainEvent
{
    public string Name { get; } = IdentityEvents.RoleGranted;
    public required Guid AccountId { get; init; }
    public required string Role { get; init; }
}

/// <summary>An account was suspended, banned or reinstated.</summary>
public sealed record AccountStatusChanged : IDomainEvent
{
    public string Name { get; } = IdentityEvents.AccountStatusChanged;
    public required Guid AccountId { get; init; }
    public required string From { get; init; }
    public required string To { get; init; }
    public required string Reason { get; init; }
    public Guid? ActorId { get; init; }
    public required IReadOnlyList<string> Roles { get; init; }
}

/// <summary>An account was closed and its personal data erased.</summary>
public sealed record AccountDeleted : IDomainEvent
{
    public string Name { get; } = IdentityEvents.AccountDeleted;
    public required Guid AccountId { get; init; }
}
