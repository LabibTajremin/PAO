using PAO.Core.Areas.Identity.Controllers;
using PAO.Core.Areas.Identity.Services;
using PAO.Lib.Areas.Identity;

namespace PAO.UnitTests.Areas.Identity;

public sealed class IdentityRulesTests
{
    private static AccountRecord Account(string status = AccountStatus.Active, DateTimeOffset? deletedAt = null) =>
        new() { Id = Guid.NewGuid(), Status = status, Roles = [], CreatedAt = DateTimeOffset.UtcNow, DeletedAt = deletedAt };

    private static AdminRecord Admin() => new() { Id = Guid.NewGuid(), Status = AccountStatus.Active, Roles = [], CreatedAt = DateTimeOffset.UtcNow, PasswordHash = "h" };

    [Fact]
    public void Refuses_sign_in_for_deleted_banned_and_suspended_accounts()
    {
        Assert.Null(IdentityRules.SignInRefusal(Account()));
        Assert.Null(IdentityRules.SignInRefusal(Account(AccountStatus.Pending)));
        Assert.Equal(IdentityReasons.AccountSuspended, IdentityRules.SignInRefusal(Account(AccountStatus.Suspended)));
        Assert.Equal(IdentityReasons.AccountBanned, IdentityRules.SignInRefusal(Account(AccountStatus.Banned)));
        Assert.Equal(IdentityReasons.AccountDeleted, IdentityRules.SignInRefusal(Account(deletedAt: DateTimeOffset.UtcNow)));
    }

    [Fact]
    public void Allows_suspend_ban_and_reinstate_but_no_no_op_or_deleted_account()
    {
        Assert.True(IdentityRules.CanChangeStatus(Account(), AccountStatus.Suspended));
        Assert.True(IdentityRules.CanChangeStatus(Account(), AccountStatus.Banned));
        Assert.True(IdentityRules.CanChangeStatus(Account(AccountStatus.Banned), AccountStatus.Active));
        Assert.False(IdentityRules.CanChangeStatus(Account(), AccountStatus.Active));
        Assert.False(IdentityRules.CanChangeStatus(Account(), AccountStatus.Pending));
        Assert.False(IdentityRules.CanChangeStatus(Account(deletedAt: DateTimeOffset.UtcNow), AccountStatus.Banned));
    }

    [Fact]
    public void Maps_apps_to_roles_and_recognises_admin_role_sets()
    {
        Assert.Equal(Roles.Provider, IdentityRules.RoleForApp("partner"));
        Assert.Equal(Roles.Customer, IdentityRules.RoleForApp("customer"));
        Assert.True(IdentityRules.IsAdminRoleSet([Roles.Verifier, Roles.SuperAdmin]));
        Assert.False(IdentityRules.IsAdminRoleSet([]));
        Assert.False(IdentityRules.IsAdminRoleSet([Roles.Customer]));
    }

    [Fact]
    public void Shares_the_contract_reasons_and_the_nestjs_values()
    {
        Assert.Equal(IdentityErrors.StatusInvalid, IdentityReasons.StatusChange);
        Assert.Equal((6, 300, 5, 60), (IdentityRules.CodeLength, (int)IdentityRules.CodeTtl.TotalSeconds, IdentityRules.CodeMaxAttempts, (int)IdentityRules.ResendAfter.TotalSeconds));
        Assert.Equal((3, 900, 10, 3600), (IdentityRules.PerPhone.Limit, (int)IdentityRules.PerPhone.Window.TotalSeconds, IdentityRules.PerIp.Limit, (int)IdentityRules.PerIp.Window.TotalSeconds));
        Assert.Equal((300, 5, 12), ((int)IdentityRules.ChallengeTtl.TotalSeconds, IdentityRules.ChallengeAttempts, IdentityRules.MinPasswordLength));
        Assert.Equal((900, 2_592_000), ((int)IdentityRules.AccessTtl.TotalSeconds, (int)IdentityRules.RefreshTtl.TotalSeconds));
        Assert.Equal(14, IdentityRules.ProviderGateScreens.Count);
        Assert.Equal("M14", IdentityRules.ProviderGateScreens[^1]);
        Assert.Equal(19, new IdentityErrorMap().Errors.Count);
    }

    [Fact]
    public void Accepts_a_matching_code_then_locks_out_on_the_fifth_wrong_guess()
    {
        Assert.Equal((true, (string?)null), IdentityRules.CheckAttempt(0, true));
        Assert.Equal((false, IdentityReasons.CodeInvalid), IdentityRules.CheckAttempt(3, false));
        Assert.Equal((true, IdentityReasons.CodeLocked), IdentityRules.CheckAttempt(4, false));
    }

    [Fact]
    public void Round_trips_refresh_tokens_and_refuses_malformed_ones()
    {
        var id = Guid.Parse("0199c4f0-0000-7000-8000-000000000001");
        Assert.Equal((id, "secret"), IdentityRules.ParseRefreshToken(IdentityRules.FormatRefreshToken(id, "secret")));
        foreach (var bad in new[] { string.Empty, "nodot", "not-a-uuid.secret", $"{id}." })
        {
            Assert.Null(IdentityRules.ParseRefreshToken(bad));
        }
        Assert.True(IdentityRules.FamilyMatches("abc", "abc"));
        Assert.False(IdentityRules.FamilyMatches("abc", "abd"));
        Assert.False(IdentityRules.FamilyMatches("abc", "abcd"));
    }

    [Fact]
    public void Locks_out_after_the_limit_for_the_lockout_period()
    {
        var now = DateTimeOffset.Parse("2026-10-09T10:00:00Z", System.Globalization.CultureInfo.InvariantCulture);
        var a = Admin();
        for (var i = 0; i < IdentityRules.AdminMaxFailures - 1; i++)
        {
            a = IdentityRules.RecordFailure(a, now);
        }
        Assert.Null(IdentityRules.AdminLoginRefusal(a, now));
        a = IdentityRules.RecordFailure(a, now);
        Assert.Equal(IdentityReasons.AdminLocked, IdentityRules.AdminLoginRefusal(a, now));
        Assert.Equal(0, a.FailedAttempts);
        Assert.Null(IdentityRules.AdminLoginRefusal(a, now + IdentityRules.AdminLockout));
        Assert.Null(IdentityRules.RecordSuccess(a).LockedUntil);
        Assert.Equal(IdentityReasons.AdminInactive, IdentityRules.AdminLoginRefusal(a with { Active = false }, now));
    }

    [Theory]
    [InlineData("short1", false)]
    [InlineData("onlyletterslongenough", false)]
    [InlineData("123456789012345", false)]
    [InlineData("correct horse battery 2026", true)]
    [InlineData("😀😀😀😀😀😀😀😀😀😀a", false)]
    public void Judges_passwords(string password, bool strong)
    {
        Assert.Equal(strong, IdentityRules.IsStrongPassword(password));
    }

    [Fact]
    public void The_admin_cookie_is_http_only_and_clears_with_a_zero_age()
    {
        Assert.Equal("pao_refresh=t; Path=/v1/auth; Max-Age=60; HttpOnly; Secure; SameSite=Strict", AuthController.Cookie("t", TimeSpan.FromMinutes(1)));
        Assert.Contains("Max-Age=0", AuthController.Cookie(string.Empty, TimeSpan.Zero), StringComparison.Ordinal);
    }
}
