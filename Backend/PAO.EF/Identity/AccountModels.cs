namespace PAO.EF.Identity;

/// <summary>A row of `identity.accounts`; customers, merchants and admins share it.</summary>
public sealed class Account
{
    /// <summary>The id.</summary>
    public Guid Id { get; set; }
    /// <summary>The E.164 phone; null for email-only and erased accounts.</summary>
    public string? Phone { get; set; }
    /// <summary>The lower-case email; null for phone-only and erased accounts.</summary>
    public string? Email { get; set; }
    /// <summary>The name.</summary>
    public string Name { get; set; } = string.Empty;
    /// <summary>The PRD §6.4 status.</summary>
    public string Status { get; set; } = string.Empty;
    /// <summary>The created at.</summary>
    public DateTimeOffset CreatedAt { get; set; }
    /// <summary>The updated at.</summary>
    public DateTimeOffset UpdatedAt { get; set; }
    /// <summary>When the person erased the account (PRD §11).</summary>
    public DateTimeOffset? DeletedAt { get; set; }
}

/// <summary>A row of `identity.account_roles`.</summary>
public sealed class AccountRole
{
    /// <summary>The account id.</summary>
    public Guid AccountId { get; set; }
    /// <summary>The role.</summary>
    public string Role { get; set; } = string.Empty;
    /// <summary>The granted at.</summary>
    public DateTimeOffset GrantedAt { get; set; }
}

/// <summary>A row of `identity.admin_credentials`; the TOTP secret is encrypted.</summary>
public sealed class AdminCredentials
{
    /// <summary>The account id.</summary>
    public Guid AccountId { get; set; }
    /// <summary>The Argon2id password hash.</summary>
    public string PasswordHash { get; set; } = string.Empty;
    /// <summary>Whether the admin still uses the invite's temporary password.</summary>
    public bool MustChangePassword { get; set; }
    /// <summary>The authenticator secret, encrypted with the data key.</summary>
    public byte[]? TotpSecretEnc { get; set; }
    /// <summary>Whether TOTP enrolment is complete.</summary>
    public bool TotpEnrolled { get; set; }
    /// <summary>Wrong passwords since the last success or lockout.</summary>
    public int FailedAttempts { get; set; }
    /// <summary>The end of the current lockout.</summary>
    public DateTimeOffset? LockedUntil { get; set; }
    /// <summary>Whether the admin may sign in.</summary>
    public bool Active { get; set; }
    /// <summary>The last login at.</summary>
    public DateTimeOffset? LastLoginAt { get; set; }
}

/// <summary>A row of `identity.blocked_phones`: phones of banned identities (PRD §6.4).</summary>
public sealed class BlockedPhone
{
    /// <summary>The phone.</summary>
    public string Phone { get; set; } = string.Empty;
    /// <summary>The reason.</summary>
    public string Reason { get; set; } = string.Empty;
    /// <summary>The blocked at.</summary>
    public DateTimeOffset BlockedAt { get; set; }
}
