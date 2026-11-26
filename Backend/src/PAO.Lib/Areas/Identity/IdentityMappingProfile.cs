using PAO.Lib.Common;
using PAO.Lib.Mapping;

namespace PAO.Lib.Areas.Identity;

/// <summary>The Identity area's maps: records to API views and to the shared contract.</summary>
public sealed class IdentityMappingProfile : IMappingProfile
{
    /// <inheritdoc />
    public void Configure(MappingRegistry registry)
    {
        AddAccountMaps(registry);
        AddAdminMaps(registry);
    }

    private static void AddAccountMaps(MappingRegistry registry) => registry
        .Add<AccountRecord, AccountView>((a, _) => new AccountView
        {
            Id = a.Id.ToString(),
            Phone = a.Phone.Length == 0 ? null : a.Phone,
            Email = a.Email.Length == 0 ? null : a.Email,
            Roles = a.Roles,
            Status = a.Status,
            CreatedAt = IsoTime.Format(a.CreatedAt),
        })
        .Add<AccountRecord, Account>((a, _) => new Account
        {
            Id = a.Id,
            Phone = a.Phone,
            Email = a.Email,
            Roles = [.. a.Roles.Order(StringComparer.Ordinal)],
            Status = a.Status,
            CreatedAt = a.CreatedAt,
        })
        .Add<TokenPairResult, TokenPairView>((t, m) => new TokenPairView
        {
            AccessToken = t.Session.AccessToken,
            RefreshToken = t.IncludeRefresh ? t.Session.RefreshToken : null,
            ExpiresInSeconds = t.Session.ExpiresInSeconds,
            IsNewAccount = t.Session.IsNewAccount,
            Account = m.Map<AccountRecord, AccountView>(t.Session.Account),
        })
        .Add<PermissionsResult, MyPermissionsView>((p, _) => new MyPermissionsView(p.Roles, p.Permissions, p.Screens, p.ProviderGate));

    private static void AddAdminMaps(MappingRegistry registry) => registry
        .Add<AdminChallengeResult, AdminLoginChallengeView>((c, _) => new AdminLoginChallengeView
        {
            ChallengeId = c.Id.ToString(),
            ExpiresInSeconds = c.ExpiresInSeconds,
            TotpEnrolment = c.EnrolSecret.Length == 0 ? null : new TotpEnrolmentView(c.EnrolSecret, c.EnrolUrl),
            MustChangePassword = c.MustChangePassword,
        })
        .Add<AdminRecord, AdminUserView>((a, _) => new AdminUserView
        {
            Id = a.Id.ToString(),
            Email = a.Email,
            Name = a.Name,
            Roles = a.Roles,
            Active = a.Active,
            TotpEnrolled = a.TotpEnrolled,
            LastLoginAt = a.LastLoginAt is { } at ? IsoTime.Format(at) : null,
        })
        .Add<InvitedAdmin, AdminUserInvitedView>((i, m) => new AdminUserInvitedView(m.Map<AdminRecord, AdminUserView>(i.Admin), i.TemporaryPassword))
        .Add<RoleDefinitionRecord, RoleDefinitionView>((r, _) => new RoleDefinitionView(r.Role, r.Permissions, r.Screens))
        .Add<RoleCatalogue, RoleListView>((c, m) => new RoleListView(
            m.MapAll<RoleDefinitionRecord, RoleDefinitionView>(c.Roles), c.AllPermissions, c.AllScreens));
}
