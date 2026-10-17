namespace PAO.Lib.Areas.Identity;

/// <summary>Role names as stored in `identity.roles`.</summary>
public static class Roles
{
    public const string Customer = "customer";
    public const string Provider = "provider";
    public const string Verifier = "verifier";
    public const string CatalogManager = "catalog_manager";
    public const string SupportAgent = "support_agent";
    public const string SuperAdmin = "super_admin";

    /// <summary>The roles of the admin console (`identity.roles.is_admin`).</summary>
    public static readonly IReadOnlySet<string> Admin =
        new HashSet<string>(StringComparer.Ordinal) { Verifier, CatalogManager, SupportAgent, SuperAdmin };
}

/// <summary>Account statuses (PRD §6.4).</summary>
public static class AccountStatus
{
    public const string Pending = "pending";
    public const string Active = "active";
    public const string Suspended = "suspended";
    public const string Banned = "banned";
}

/// <summary>What a one-time code is for.</summary>
public static class CodePurpose
{
    public const string Login = "login";
    public const string DeleteAccount = "delete_account";
    public const string EmergencyContact = "emergency_contact";
}

/// <summary>An account as other areas see it.</summary>
public sealed record Account
{
    public required Guid Id { get; init; }
    public required string Phone { get; init; }
    public required string Email { get; init; }
    public required IReadOnlyList<string> Roles { get; init; }
    public required string Status { get; init; }
    public required DateTimeOffset CreatedAt { get; init; }
}

/// <summary>Suspends, bans or reinstates an account.</summary>
public sealed record SetAccountStatusInput
{
    public required Guid AccountId { get; init; }
    public required string Status { get; init; }
    public required string Reason { get; init; }
    public Guid? ActorId { get; init; }
}

/// <summary>The Identity area's error reasons.</summary>
public static class IdentityErrors
{
    public const string AccountNotFound = "identity.account_not_found";
    public const string CodeInvalid = "identity.code_invalid";
    public const string CodeExpired = "identity.code_expired";
    public const string CodeLocked = "identity.code_locked";
    public const string RateLimited = "identity.rate_limited";
    public const string StatusInvalid = "identity.status_invalid";
}
