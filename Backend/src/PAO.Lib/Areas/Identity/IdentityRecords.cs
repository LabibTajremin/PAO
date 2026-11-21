namespace PAO.Lib.Areas.Identity;

/// <summary>One person's identity inside the Identity area; customer and merchant roles share it (PRD §3).</summary>
public record AccountRecord
{
    /// <summary>The id.</summary>
    public required Guid Id { get; init; }
    /// <summary>The E.164 phone; empty for email-only accounts and after deletion.</summary>
    public string Phone { get; init; } = string.Empty;
    /// <summary>The lower-case email; empty for phone-only accounts.</summary>
    public string Email { get; init; } = string.Empty;
    /// <summary>The name.</summary>
    public string Name { get; init; } = string.Empty;
    /// <summary>The PRD §6.4 status.</summary>
    public required string Status { get; init; }
    /// <summary>The roles, sorted.</summary>
    public required IReadOnlyList<string> Roles { get; init; }
    /// <summary>The created at.</summary>
    public required DateTimeOffset CreatedAt { get; init; }
    /// <summary>When the person erased the account.</summary>
    public DateTimeOffset? DeletedAt { get; init; }
}

/// <summary>An operations staff member's account plus credentials.</summary>
public sealed record AdminRecord : AccountRecord
{
    /// <summary>The Argon2id password hash.</summary>
    public required string PasswordHash { get; init; }
    /// <summary>Whether the invite's temporary password is still in use.</summary>
    public bool MustChangePassword { get; init; }
    /// <summary>The authenticator secret once enrolled, else empty; encrypted at rest.</summary>
    public string TotpSecret { get; init; } = string.Empty;
    /// <summary>Whether TOTP enrolment is complete.</summary>
    public bool TotpEnrolled { get; init; }
    /// <summary>Wrong passwords since the last success or lockout.</summary>
    public int FailedAttempts { get; init; }
    /// <summary>The end of the current lockout.</summary>
    public DateTimeOffset? LockedUntil { get; init; }
    /// <summary>Whether the admin may sign in.</summary>
    public bool Active { get; init; } = true;
    /// <summary>The last login at.</summary>
    public DateTimeOffset? LastLoginAt { get; init; }
}

/// <summary>What a successful sign-in or refresh returns.</summary>
public sealed record SessionResult
{
    /// <summary>The access token.</summary>
    public required string AccessToken { get; init; }
    /// <summary>The refresh token, `{familyId}.{secret}`.</summary>
    public required string RefreshToken { get; init; }
    /// <summary>The access token's lifetime in seconds.</summary>
    public required int ExpiresInSeconds { get; init; }
    /// <summary>The account.</summary>
    public required AccountRecord Account { get; init; }
    /// <summary>Whether this sign-in created the account.</summary>
    public required bool IsNewAccount { get; init; }
}

/// <summary>A session as answered over HTTP: the admin web app gets its refresh token as a cookie instead.</summary>
public sealed record TokenPairResult(SessionResult Session, bool IncludeRefresh);

/// <summary>The first admin login step's result.</summary>
public sealed record AdminChallengeResult
{
    /// <summary>The challenge id.</summary>
    public required Guid Id { get; init; }
    /// <summary>The new authenticator secret on the first login; empty afterwards.</summary>
    public required string EnrolSecret { get; init; }
    /// <summary>The otpauth:// URL for the new secret; empty afterwards.</summary>
    public required string EnrolUrl { get; init; }
    /// <summary>Whether the admin must replace the temporary password.</summary>
    public required bool MustChangePassword { get; init; }
    /// <summary>How long the second step waits, in seconds.</summary>
    public required int ExpiresInSeconds { get; init; }
}

/// <summary>What the signed-in account may do and see.</summary>
public sealed record PermissionsResult(IReadOnlyList<string> Roles, IReadOnlyList<string> Permissions, IReadOnlyList<string> Screens, bool ProviderGate);

/// <summary>A role with its grants.</summary>
public sealed record RoleDefinitionRecord(string Role, IReadOnlyList<string> Permissions, IReadOnlyList<string> Screens);

/// <summary>Every role plus every known permission and screen, for the role editor (A-10).</summary>
public sealed record RoleCatalogue(IReadOnlyList<RoleDefinitionRecord> Roles, IReadOnlyList<string> AllPermissions, IReadOnlyList<string> AllScreens);

/// <summary>A new admin and the one-time password shown to whoever invited them.</summary>
public sealed record InvitedAdmin(AdminRecord Admin, string TemporaryPassword);
