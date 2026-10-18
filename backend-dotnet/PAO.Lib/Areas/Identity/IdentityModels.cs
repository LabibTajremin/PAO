using System.Text.Json.Serialization;

namespace PAO.Lib.Areas.Identity;

/// <summary>Body of requestOtp.</summary>
public sealed record OtpRequestBody
{
    /// <summary>The phone as typed.</summary>
    public string Phone { get; init; } = string.Empty;
    /// <summary>`login` (default) or `delete_account`.</summary>
    public string? Purpose { get; init; }
}

/// <summary>Body of verifyOtp.</summary>
public sealed record OtpVerifyBody
{
    /// <summary>The phone.</summary>
    public string Phone { get; init; } = string.Empty;
    /// <summary>The code.</summary>
    public string Code { get; init; } = string.Empty;
    /// <summary>`customer` or `partner`.</summary>
    public string App { get; init; } = string.Empty;
}

/// <summary>Body of refreshToken; the admin web app sends none and relies on its cookie.</summary>
public sealed record RefreshBody
{
    /// <summary>The refresh token.</summary>
    public string? RefreshToken { get; init; }
}

/// <summary>Body of logout.</summary>
public sealed record LogoutBody
{
    /// <summary>Whether to end every session of the account.</summary>
    public bool? AllDevices { get; init; }
}

/// <summary>Body of adminLogin.</summary>
public sealed record AdminLoginBody
{
    /// <summary>The email.</summary>
    public string Email { get; init; } = string.Empty;
    /// <summary>The password.</summary>
    public string Password { get; init; } = string.Empty;
}

/// <summary>Body of adminVerifyTotp.</summary>
public sealed record AdminTotpBody
{
    /// <summary>The challenge id.</summary>
    public string ChallengeId { get; init; } = string.Empty;
    /// <summary>The authenticator code.</summary>
    public string Code { get; init; } = string.Empty;
}

/// <summary>Body of changeAdminPassword.</summary>
public sealed record AdminPasswordChangeBody
{
    /// <summary>The current password.</summary>
    public string CurrentPassword { get; init; } = string.Empty;
    /// <summary>The new password.</summary>
    public string NewPassword { get; init; } = string.Empty;
}

/// <summary>Body of deleteMe.</summary>
public sealed record DeleteAccountBody
{
    /// <summary>The `delete_account` code.</summary>
    public string Code { get; init; } = string.Empty;
}

/// <summary>Body of inviteAdminUser.</summary>
public sealed record AdminUserInviteBody
{
    /// <summary>The email.</summary>
    public string Email { get; init; } = string.Empty;
    /// <summary>The name.</summary>
    public string Name { get; init; } = string.Empty;
    /// <summary>The admin roles.</summary>
    public IReadOnlyList<string> Roles { get; init; } = [];
}

/// <summary>Body of updateAdminUser; absent fields stay as they are.</summary>
public sealed record AdminUserUpdateBody
{
    /// <summary>The roles.</summary>
    public IReadOnlyList<string>? Roles { get; init; }
    /// <summary>The active flag.</summary>
    public bool? Active { get; init; }
}

/// <summary>Body of updateRole.</summary>
public sealed record RoleUpdateBody
{
    /// <summary>The permissions.</summary>
    public IReadOnlyList<string> Permissions { get; init; } = [];
    /// <summary>The screens.</summary>
    public IReadOnlyList<string> Screens { get; init; } = [];
}

/// <summary>The spec's OtpRequestAccepted.</summary>
public sealed record OtpRequestAcceptedView(int ExpiresInSeconds, int ResendAfterSeconds);

/// <summary>The spec's Account; absent phone or email are left out.</summary>
public sealed record AccountView
{
    /// <summary>The id.</summary>
    public required string Id { get; init; }
    /// <summary>The phone.</summary>
    [JsonIgnore(Condition = JsonIgnoreCondition.WhenWritingNull)]
    public string? Phone { get; init; }
    /// <summary>The email.</summary>
    [JsonIgnore(Condition = JsonIgnoreCondition.WhenWritingNull)]
    public string? Email { get; init; }
    /// <summary>The roles.</summary>
    public required IReadOnlyList<string> Roles { get; init; }
    /// <summary>The status.</summary>
    public required string Status { get; init; }
    /// <summary>The created at.</summary>
    public required string CreatedAt { get; init; }
}

/// <summary>The spec's TokenPair.</summary>
public sealed record TokenPairView
{
    /// <summary>The access token.</summary>
    public required string AccessToken { get; init; }
    /// <summary>The refresh token; left out for the admin web app.</summary>
    [JsonIgnore(Condition = JsonIgnoreCondition.WhenWritingNull)]
    public string? RefreshToken { get; init; }
    /// <summary>The expires in seconds.</summary>
    public required int ExpiresInSeconds { get; init; }
    /// <summary>Whether this sign-in created the account.</summary>
    public required bool IsNewAccount { get; init; }
    /// <summary>The account.</summary>
    public required AccountView Account { get; init; }
}

/// <summary>The spec's TotpEnrolment.</summary>
public sealed record TotpEnrolmentView(string Secret, string OtpauthUrl);

/// <summary>The spec's AdminLoginChallenge.</summary>
public sealed record AdminLoginChallengeView
{
    /// <summary>The challenge id.</summary>
    public required string ChallengeId { get; init; }
    /// <summary>The expires in seconds.</summary>
    public required int ExpiresInSeconds { get; init; }
    /// <summary>The enrolment on the first login.</summary>
    [JsonIgnore(Condition = JsonIgnoreCondition.WhenWritingNull)]
    public TotpEnrolmentView? TotpEnrolment { get; init; }
    /// <summary>Whether the temporary password must be replaced.</summary>
    public required bool MustChangePassword { get; init; }
}

/// <summary>The spec's MyPermissions.</summary>
public sealed record MyPermissionsView(IReadOnlyList<string> Roles, IReadOnlyList<string> Permissions, IReadOnlyList<string> Screens, bool ProviderGate);

/// <summary>The spec's AdminUser.</summary>
public sealed record AdminUserView
{
    /// <summary>The id.</summary>
    public required string Id { get; init; }
    /// <summary>The email.</summary>
    public required string Email { get; init; }
    /// <summary>The name.</summary>
    public required string Name { get; init; }
    /// <summary>The roles.</summary>
    public required IReadOnlyList<string> Roles { get; init; }
    /// <summary>The active flag.</summary>
    public required bool Active { get; init; }
    /// <summary>Whether TOTP is enrolled.</summary>
    public required bool TotpEnrolled { get; init; }
    /// <summary>The last login at.</summary>
    [JsonIgnore(Condition = JsonIgnoreCondition.WhenWritingNull)]
    public string? LastLoginAt { get; init; }
}

/// <summary>The spec's AdminUserList.</summary>
public sealed record AdminUserListView(IReadOnlyList<AdminUserView> Items);

/// <summary>The spec's AdminUserInvited.</summary>
public sealed record AdminUserInvitedView(AdminUserView User, string TemporaryPassword);

/// <summary>The spec's RoleDefinition.</summary>
public sealed record RoleDefinitionView(string Role, IReadOnlyList<string> Permissions, IReadOnlyList<string> Screens);

/// <summary>A session answered with the raw refresh token too, for controllers that set the admin cookie.</summary>
public sealed record CookieSession(TokenPairView View, string RefreshToken);

/// <summary>The spec's RoleList.</summary>
public sealed record RoleListView(IReadOnlyList<RoleDefinitionView> Items, IReadOnlyList<string> AllPermissions, IReadOnlyList<string> AllScreens);
