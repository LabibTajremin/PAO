namespace PAO.Lib.Areas.Identity;

/// <summary>Role names as stored in `identity.roles`.</summary>
public static class Roles
{
    /// <summary>The `"customer"` value.</summary>
    public const string Customer = "customer";
    /// <summary>The `"provider"` value.</summary>
    public const string Provider = "provider";
    /// <summary>The `"verifier"` value.</summary>
    public const string Verifier = "verifier";
    /// <summary>The `"catalog_manager"` value.</summary>
    public const string CatalogManager = "catalog_manager";
    /// <summary>The `"support_agent"` value.</summary>
    public const string SupportAgent = "support_agent";
    /// <summary>The `"super_admin"` value.</summary>
    public const string SuperAdmin = "super_admin";

    /// <summary>The roles of the admin console (`identity.roles.is_admin`).</summary>
    public static readonly IReadOnlySet<string> Admin =
        new HashSet<string>(StringComparer.Ordinal) { Verifier, CatalogManager, SupportAgent, SuperAdmin };
}

/// <summary>Account statuses (PRD §6.4).</summary>
public static class AccountStatus
{
    /// <summary>The `"pending"` value.</summary>
    public const string Pending = "pending";
    /// <summary>The `"active"` value.</summary>
    public const string Active = "active";
    /// <summary>The `"suspended"` value.</summary>
    public const string Suspended = "suspended";
    /// <summary>The `"banned"` value.</summary>
    public const string Banned = "banned";
}

/// <summary>What a one-time code is for.</summary>
public static class CodePurpose
{
    /// <summary>The `"login"` value.</summary>
    public const string Login = "login";
    /// <summary>The `"delete_account"` value.</summary>
    public const string DeleteAccount = "delete_account";
    /// <summary>The `"emergency_contact"` value.</summary>
    public const string EmergencyContact = "emergency_contact";
}

/// <summary>An account as other areas see it.</summary>
public sealed record Account
{
    /// <summary>The id.</summary>
    public required Guid Id { get; init; }
    /// <summary>The phone.</summary>
    public required string Phone { get; init; }
    /// <summary>The email.</summary>
    public required string Email { get; init; }
    /// <summary>The roles.</summary>
    public required IReadOnlyList<string> Roles { get; init; }
    /// <summary>The status.</summary>
    public required string Status { get; init; }
    /// <summary>The created at.</summary>
    public required DateTimeOffset CreatedAt { get; init; }
}

/// <summary>Suspends, bans or reinstates an account.</summary>
public sealed record SetAccountStatusInput
{
    /// <summary>The account id.</summary>
    public required Guid AccountId { get; init; }
    /// <summary>The status.</summary>
    public required string Status { get; init; }
    /// <summary>The reason.</summary>
    public required string Reason { get; init; }
    /// <summary>The actor id.</summary>
    public Guid? ActorId { get; init; }
}

/// <summary>The Identity area's error reasons.</summary>
public static class IdentityErrors
{
    /// <summary>The `"identity.account_not_found"` value.</summary>
    public const string AccountNotFound = "identity.account_not_found";
    /// <summary>The `"identity.code_invalid"` value.</summary>
    public const string CodeInvalid = "identity.code_invalid";
    /// <summary>The `"identity.code_expired"` value.</summary>
    public const string CodeExpired = "identity.code_expired";
    /// <summary>The `"identity.code_locked"` value.</summary>
    public const string CodeLocked = "identity.code_locked";
    /// <summary>The `"identity.rate_limited"` value.</summary>
    public const string RateLimited = "identity.rate_limited";
    /// <summary>The `"identity.status_invalid"` value.</summary>
    public const string StatusInvalid = "identity.status_invalid";
}
