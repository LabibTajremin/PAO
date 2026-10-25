using System.Security.Cryptography;
using System.Text;
using System.Text.RegularExpressions;
using PAO.Infrastructure.Crypto;
using PAO.Lib.Areas.Identity;

namespace PAO.Core.Areas.Identity.Services;

/// <summary>The identity rules and their values, unchanged across releases.</summary>
public static partial class IdentityRules
{
    /// <summary>Digits in a one-time code.</summary>
    public const int CodeLength = 6;
    /// <summary>Wrong guesses allowed before a code is discarded.</summary>
    public const int CodeMaxAttempts = 5;
    /// <summary>Wrong passwords before an admin is locked out (A-01).</summary>
    public const int AdminMaxFailures = 5;
    /// <summary>Wrong authenticator codes before the challenge is dropped.</summary>
    public const int ChallengeAttempts = 5;
    /// <summary>The shortest admin password.</summary>
    public const int MinPasswordLength = 12;
    /// <summary>How long a code stays valid.</summary>
    public static readonly TimeSpan CodeTtl = TimeSpan.FromMinutes(5);
    /// <summary>The wait between two codes to one phone.</summary>
    public static readonly TimeSpan ResendAfter = TimeSpan.FromMinutes(1);
    /// <summary>Codes per phone per window.</summary>
    public static readonly (int Limit, TimeSpan Window) PerPhone = (3, TimeSpan.FromMinutes(15));
    /// <summary>Codes per client IP per window.</summary>
    public static readonly (int Limit, TimeSpan Window) PerIp = (10, TimeSpan.FromHours(1));
    /// <summary>How long a lockout lasts.</summary>
    public static readonly TimeSpan AdminLockout = TimeSpan.FromMinutes(15);
    /// <summary>How long the second login step waits.</summary>
    public static readonly TimeSpan ChallengeTtl = TimeSpan.FromMinutes(5);
    /// <summary>Access tokens live 15 minutes.</summary>
    public static readonly TimeSpan AccessTtl = TimeSpan.FromMinutes(15);
    /// <summary>A refresh family lives 30 days after its last rotation.</summary>
    public static readonly TimeSpan RefreshTtl = TimeSpan.FromDays(30);

    /// <summary>The only partner screens a merchant sees before Level 1 (PRD §8.5): M01–M14.</summary>
    public static readonly IReadOnlyList<string> ProviderGateScreens = [.. Enumerable.Range(1, 14).Select(i => $"M{i:00}")];

    /// <summary>Why the account may not sign in, or null when it may.</summary>
    public static string? SignInRefusal(AccountRecord a) =>
        a.DeletedAt is not null ? IdentityReasons.AccountDeleted
        : a.Status == AccountStatus.Banned ? IdentityReasons.AccountBanned
        : a.Status == AccountStatus.Suspended ? IdentityReasons.AccountSuspended : null;

    /// <summary>The partner app makes the person a merchant (`provider`), the customer app a customer.</summary>
    public static string RoleForApp(string app) => app == "partner" ? Roles.Provider : Roles.Customer;

    /// <summary>A live account may be suspended, banned or reinstated, never to its current status.</summary>
    public static bool CanChangeStatus(AccountRecord a, string to) =>
        a.DeletedAt is null && a.Status != to && to != AccountStatus.Pending;

    /// <summary>At least one role, and every role an admin role.</summary>
    public static bool IsAdminRoleSet(IReadOnlyCollection<string> roles) => roles.Count > 0 && roles.All(Roles.Admin.Contains);

    /// <summary>Why the admin may not log in now, or null.</summary>
    public static string? AdminLoginRefusal(AdminRecord a, DateTimeOffset now) =>
        !a.Active || a.DeletedAt is not null ? IdentityReasons.AdminInactive
        : a.LockedUntil is { } until && now < until ? IdentityReasons.AdminLocked : null;

    /// <summary>Counts a wrong password; reaching the limit locks out and restarts the count.</summary>
    public static AdminRecord RecordFailure(AdminRecord a, DateTimeOffset now) =>
        a.FailedAttempts + 1 < AdminMaxFailures
            ? a with { FailedAttempts = a.FailedAttempts + 1 }
            : a with { FailedAttempts = 0, LockedUntil = now + AdminLockout };

    /// <summary>Clears failures after a correct password.</summary>
    public static AdminRecord RecordSuccess(AdminRecord a) => a with { FailedAttempts = 0, LockedUntil = null };

    /// <summary>A passphrase-length password with letters and at least one other kind of character.</summary>
    public static bool IsStrongPassword(string pw) =>
        SurrogatePair().Replace(pw, "_").Length >= MinPasswordLength && pw.Any(char.IsLetter) && pw.Any(c => !char.IsLetter(c));

    /// <summary>Applies a guess: whether to drop the stored code, and why it failed (null on a match).</summary>
    public static (bool Discard, string? Refusal) CheckAttempt(int attempts, bool matched) =>
        matched ? (true, null)
        : attempts + 1 >= CodeMaxAttempts ? (true, IdentityReasons.CodeLocked)
        : (false, IdentityReasons.CodeInvalid);

    /// <summary>Joins the family id and the secret so a refresh can find its family.</summary>
    public static string FormatRefreshToken(Guid familyId, string secret) => $"{familyId}.{secret}";

    /// <summary>Splits a refresh token, or null when malformed.</summary>
    public static (Guid FamilyId, string Secret)? ParseRefreshToken(string token)
    {
        var dot = token.IndexOf('.', StringComparison.Ordinal);
        if (dot < 0 || !UuidText.IsValid(token[..dot]) || dot == token.Length - 1)
        {
            return null;
        }
        return (Guid.Parse(token[..dot]), token[(dot + 1)..]);
    }

    /// <summary>Compares a presented token hash with the family's current one in constant time.</summary>
    public static bool FamilyMatches(string currentHash, string hash) =>
        CryptographicOperations.FixedTimeEquals(Encoding.UTF8.GetBytes(currentHash), Encoding.UTF8.GetBytes(hash));

    /// <summary>The E.164 phone, or throws InvalidPhone.</summary>
    public static string PhoneOrFail(string raw) =>
        PhoneNumber.Normalize(raw) ?? throw new PAO.Lib.Errors.DomainException(IdentityReasons.InvalidPhone);

    // Counts a surrogate pair as one character, as the contract defines it.
    [GeneratedRegex("[\uD800-\uDBFF][\uDC00-\uDFFF]")]
    private static partial Regex SurrogatePair();
}
