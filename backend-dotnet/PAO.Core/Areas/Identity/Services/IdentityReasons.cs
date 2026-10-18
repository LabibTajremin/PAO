using PAO.Infrastructure.Http.Errors;
using PAO.Lib.Areas.Identity;

namespace PAO.Core.Areas.Identity.Services;

/// <summary>Why an identity rule refused something; the values shared with the contract equal <see cref="IdentityErrors"/>.</summary>
public static class IdentityReasons
{
    /// <summary>The `"identity.invalid_phone"` value.</summary>
    public const string InvalidPhone = "identity.invalid_phone";
    /// <summary>The account id or phone is unknown.</summary>
    public const string AccountNotFound = IdentityErrors.AccountNotFound;
    /// <summary>The `"identity.account_banned"` value.</summary>
    public const string AccountBanned = "identity.account_banned";
    /// <summary>The `"identity.account_suspended"` value.</summary>
    public const string AccountSuspended = "identity.account_suspended";
    /// <summary>The `"identity.account_deleted"` value.</summary>
    public const string AccountDeleted = "identity.account_deleted";
    /// <summary>The status change is not allowed.</summary>
    public const string StatusChange = IdentityErrors.StatusInvalid;
    /// <summary>The code is wrong.</summary>
    public const string CodeInvalid = IdentityErrors.CodeInvalid;
    /// <summary>The code expired or was never sent.</summary>
    public const string CodeExpired = IdentityErrors.CodeExpired;
    /// <summary>Too many wrong codes.</summary>
    public const string CodeLocked = IdentityErrors.CodeLocked;
    /// <summary>Too many codes requested.</summary>
    public const string RateLimited = IdentityErrors.RateLimited;
    /// <summary>The `"identity.refresh_invalid"` value.</summary>
    public const string RefreshInvalid = "identity.refresh_invalid";
    /// <summary>The `"identity.refresh_reused"` value.</summary>
    public const string RefreshReused = "identity.refresh_reused";
    /// <summary>The `"identity.invalid_credentials"` value.</summary>
    public const string InvalidCredentials = "identity.invalid_credentials";
    /// <summary>The `"identity.admin_locked"` value.</summary>
    public const string AdminLocked = "identity.admin_locked";
    /// <summary>The `"identity.admin_inactive"` value.</summary>
    public const string AdminInactive = "identity.admin_inactive";
    /// <summary>The `"identity.challenge_expired"` value.</summary>
    public const string ChallengeExpired = "identity.challenge_expired";
    /// <summary>The `"identity.totp_invalid"` value.</summary>
    public const string TotpInvalid = "identity.totp_invalid";
    /// <summary>The `"identity.email_taken"` value.</summary>
    public const string EmailTaken = "identity.email_taken";
    /// <summary>The `"identity.role_invalid"` value.</summary>
    public const string RoleInvalid = "identity.role_invalid";
    /// <summary>The `"identity.password_too_weak"` value.</summary>
    public const string PasswordTooWeak = "identity.password_too_weak";
}

/// <summary>Identity's reasons as API errors, as the NestJS and Go APIs answered them.</summary>
public sealed class IdentityErrorMap : IErrorMap
{
    private static readonly ApiError SignInAgain = new(401, "REFRESH_TOKEN_INVALID", "Sign in again.");

    /// <inheritdoc />
    public IReadOnlyDictionary<string, ApiError> Errors { get; } = new Dictionary<string, ApiError>
    {
        [IdentityReasons.InvalidPhone] = ApiErrors.Validation("field", "phone"),
        [IdentityReasons.AccountNotFound] = ApiErrors.NotFound,
        [IdentityReasons.AccountBanned] = new(403, "ACCOUNT_BANNED", "This account is banned."),
        [IdentityReasons.AccountSuspended] = new(403, "ACCOUNT_SUSPENDED", "This account is suspended."),
        [IdentityReasons.AccountDeleted] = ApiErrors.Unauthenticated,
        [IdentityReasons.StatusChange] = new(409, "CONFLICT", "The account is already in that state."),
        [IdentityReasons.CodeInvalid] = new(401, "OTP_INVALID", "The code is wrong."),
        [IdentityReasons.CodeExpired] = new(401, "OTP_EXPIRED", "The code expired. Ask for a new one."),
        [IdentityReasons.CodeLocked] = ApiErrors.RateLimited("OTP_LOCKED", IdentityRules.CodeTtl),
        [IdentityReasons.RefreshInvalid] = SignInAgain,
        [IdentityReasons.RefreshReused] = SignInAgain,
        [IdentityReasons.InvalidCredentials] = new(401, "INVALID_CREDENTIALS", "Email or password is wrong."),
        [IdentityReasons.AdminLocked] = ApiErrors.RateLimited("ACCOUNT_LOCKED", IdentityRules.AdminLockout),
        [IdentityReasons.AdminInactive] = ApiErrors.Forbidden,
        [IdentityReasons.ChallengeExpired] = new(401, "MFA_CHALLENGE_EXPIRED", "Sign in again."),
        [IdentityReasons.TotpInvalid] = new(401, "TOTP_INVALID", "The authenticator code is wrong."),
        [IdentityReasons.EmailTaken] = new(409, "CONFLICT", "That email is already used."),
        [IdentityReasons.RoleInvalid] = new(422, "ROLE_INVALID", "Unknown role, permission or screen."),
        [IdentityReasons.PasswordTooWeak] = ApiErrors.Validation("field", "newPassword"),
    };
}
