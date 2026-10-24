using PAO.Core.Areas.Identity.Features.AdminLogin.Commands;
using PAO.Core.Areas.Identity.Features.AdminUsers.Commands;
using PAO.Core.Areas.Identity.Features.AdminUsers.Queries;
using PAO.Core.Areas.Identity.Features.AdminVerifyTotp.Commands;
using PAO.Core.Areas.Identity.Features.ChangeAdminPassword.Commands;
using PAO.Core.Areas.Identity.Features.RoleEditor.Queries;
using PAO.Core.Areas.Identity.Services;
using PAO.Infrastructure.Crypto;
using PAO.Lib.Areas.Identity;
using static PAO.UnitTests.Areas.Identity.IdentityHarness;

namespace PAO.UnitTests.Areas.Identity;

public sealed class AdminTests
{
    private const string NewPassword = "a much longer passphrase 1";
    private static readonly InvalidOperationException Boom = new("boom");

    private static async Task<AdminLoginChallengeView> Login(IdentityHarness h, string email, string password) =>
        await h.AdminLogin.Handle(LoginRequest(email, password), CancellationToken.None);

    private static Guid Id(AdminLoginChallengeView challenge) => Guid.Parse(challenge.ChallengeId);

    [Fact]
    public async Task Enrols_totp_on_the_first_login_then_logs_in_with_the_stored_secret()
    {
        var h = new IdentityHarness();
        var (admin, temporary) = await h.NewAdmin();
        var ch = await Login(h, Email, temporary);
        Assert.True(ch.MustChangePassword);
        Assert.Contains("otpauth://", ch.TotpEnrolment!.OtpauthUrl, StringComparison.Ordinal);
        var s = await h.AdminTotp.Handle(TotpCommand(Id(ch), h.Totp(ch.TotpEnrolment.Secret)), CancellationToken.None);
        Assert.Equal(admin.Id.ToString(), s.View.Account.Id);
        Assert.True(h.Repo.Admins[admin.Id].TotpEnrolled);
        await h.ChangePassword.Handle(PasswordChange(admin.Id, temporary, NewPassword), CancellationToken.None);
        var again = await Login(h, Email, NewPassword);
        Assert.Equal((null, false), (again.TotpEnrolment, again.MustChangePassword));
        Assert.NotNull(await h.AdminTotp.Handle(TotpCommand(Id(again), h.Totp(ch.TotpEnrolment.Secret)), CancellationToken.None));
    }

    [Fact]
    public async Task Locks_an_admin_out_after_five_wrong_passwords()
    {
        var h = new IdentityHarness();
        await h.NewAdmin();
        Assert.Equal(IdentityReasons.InvalidCredentials, await Outcome(() => Login(h, "nobody@pao.bd", "x")));
        for (var i = 0; i < IdentityRules.AdminMaxFailures; i++)
        {
            Assert.Equal(IdentityReasons.InvalidCredentials, await Outcome(() => Login(h, Email, "wrong")));
        }
        Assert.Equal(IdentityReasons.AdminLocked, await Outcome(() => Login(h, Email, "wrong")));
    }

    [Theory]
    [InlineData("lookup")]
    [InlineData("save")]
    [InlineData("challenge")]
    public async Task Fails_the_password_step_when_a_step_fails(string step)
    {
        var h = new IdentityHarness();
        var (_, temporary) = await h.NewAdmin();
        (step == "challenge" ? (Faulty)h.Challenges : h.Repo).Faults[step switch { "lookup" => "AdminByEmail", "save" => "SaveAdmin", _ => "Save" }] = Boom;
        Assert.Same(Boom, await Outcome(() => Login(h, Email, temporary)));
    }

    [Fact]
    public async Task Fails_the_password_step_on_a_malformed_hash_or_an_admin_without_email()
    {
        var h = new IdentityHarness();
        var (admin, temporary) = await h.NewAdmin();
        h.Repo.Admins[admin.Id] = admin with { PasswordHash = "x" };
        Assert.IsType<HashMalformedException>(await Outcome(() => Login(h, Email, temporary)));
        h.Repo.Admins[admin.Id] = admin with { Email = string.Empty };
        Assert.IsType<ArgumentException>(await Outcome(() => Login(h, string.Empty, temporary)));
    }

    [Fact]
    public async Task Drops_a_challenge_after_too_many_wrong_codes()
    {
        var h = new IdentityHarness();
        var (_, temporary) = await h.NewAdmin();
        Assert.Equal(IdentityReasons.ChallengeExpired, await Outcome(() => h.AdminTotp.Handle(TotpCommand(Guid.NewGuid(), "123456"), CancellationToken.None)));
        var ch = await Login(h, Email, temporary);
        for (var i = 1; i < IdentityRules.ChallengeAttempts; i++)
        {
            Assert.Equal(IdentityReasons.TotpInvalid, await Outcome(() => h.AdminTotp.Handle(TotpCommand(Id(ch), "000000"), CancellationToken.None)));
        }
        Assert.Equal(IdentityReasons.ChallengeExpired, await Outcome(() => h.AdminTotp.Handle(TotpCommand(Id(ch), "000000"), CancellationToken.None)));
        Assert.False(new AdminVerifyTotpValidator().Validate(TotpCommand(Guid.NewGuid(), "1") with { ChallengeId = "x" }).IsValid);
    }

    [Theory]
    [InlineData("repo", "AdminById")]
    [InlineData("challenges", "Delete")]
    [InlineData("repo", "SaveAdmin")]
    public async Task Fails_the_totp_step_when_a_step_fails(string fake, string method)
    {
        var h = new IdentityHarness();
        var (_, temporary) = await h.NewAdmin();
        var ch = await Login(h, Email, temporary);
        (fake == "repo" ? (Faulty)h.Repo : h.Challenges).Faults[method] = Boom;
        Assert.Same(Boom, await Outcome(() => h.AdminTotp.Handle(TotpCommand(Id(ch), h.Totp(ch.TotpEnrolment!.Secret)), CancellationToken.None)));
    }

    [Fact]
    public async Task Refuses_wrong_current_passwords_weak_passwords_and_broken_hashes()
    {
        var h = new IdentityHarness();
        var (admin, temporary) = await h.NewAdmin();
        Task<object?> Change(string current, string next) => Outcome(() => h.ChangePassword.Handle(PasswordChange(admin.Id, current, next), CancellationToken.None));
        Assert.Equal(IdentityReasons.InvalidCredentials, await Change("wrong", NewPassword));
        Assert.Equal(IdentityReasons.PasswordTooWeak, await Change(temporary, "short"));
        h.Repo.Faults["AdminById"] = Boom;
        Assert.Same(Boom, await Change(temporary, "x"));
        h.Repo.Faults.Clear();
        h.Repo.Admins[admin.Id] = admin with { PasswordHash = "x" };
        Assert.IsType<HashMalformedException>(await Change(temporary, "x"));
        Assert.True(new ChangeAdminPasswordValidator().Validate(PasswordChange(admin.Id, "a", "b")).IsValid);
        Assert.True(new AdminLoginValidator().Validate(LoginRequest("a", "b")).IsValid);
    }

    [Fact]
    public async Task Creates_updates_and_lists_admins()
    {
        var h = new IdentityHarness();
        var (admin, _) = await h.NewAdmin();
        var invite = new InviteAdminUserHandler(h.AdminUsers, h.Mapper);
        Task<object?> Create(string email, string role) => Outcome(() => invite.Handle(new InviteAdminUserCommand(email, "X", [role]), CancellationToken.None));
        Assert.Equal(IdentityReasons.EmailTaken, await Create(Email, Roles.Verifier));
        Assert.Equal(IdentityReasons.RoleInvalid, await Create("x@pao.bd", Roles.Customer));
        var created = await invite.Handle(new InviteAdminUserCommand("y@pao.bd", "Y", [Roles.SupportAgent]), CancellationToken.None);
        Assert.NotEmpty(created.TemporaryPassword);
        var updated = await h.UpdateAdmin.Handle(Update(admin.Id, [Roles.SupportAgent], false), CancellationToken.None);
        Assert.Equal((false, Roles.SupportAgent), (updated.Active, updated.Roles.Single()));
        Assert.Equal(IdentityReasons.RoleInvalid, await Outcome(() => h.UpdateAdmin.Handle(Update(admin.Id, [Roles.Customer], null), CancellationToken.None)));
        var kept = await h.UpdateAdmin.Handle(Update(admin.Id, null, null), CancellationToken.None);
        Assert.Equal((false, Roles.SupportAgent), (kept.Active, kept.Roles.Single()));
        Assert.Equal(2, (await new ListAdminUsersHandler(h.Repo, h.Mapper).Handle(new ListAdminUsersQuery(), CancellationToken.None)).Items.Count);
        Assert.True(new InviteAdminUserValidator().Validate(new InviteAdminUserCommand("a", "b", [])).IsValid);
        Assert.True(new UpdateAdminUserValidator().Validate(Update(admin.Id, null, null)).IsValid);
        Assert.True(new ListAdminUsersValidator().Validate(new ListAdminUsersQuery()).IsValid);
        Assert.True(new ListRolesValidator().Validate(RolesQuery).IsValid);
    }

    [Theory]
    [InlineData("AdminByEmail")]
    [InlineData("CreateAccount")]
    [InlineData("SetRoles")]
    [InlineData("CreateAdminCredentials")]
    public async Task Fails_to_create_when_a_step_fails(string step)
    {
        var h = new IdentityHarness();
        h.Repo.Faults[step] = Boom;
        Assert.Same(Boom, await Outcome(() => h.AdminUsers.Create("a@pao.bd", "A", [Roles.Verifier], CancellationToken.None)));
    }

    [Theory]
    [InlineData("repo", "AdminById")]
    [InlineData("repo", "SetRoles")]
    [InlineData("families", "ListForAccount")]
    public async Task Fails_to_update_when_a_step_fails(string fake, string method)
    {
        var h = new IdentityHarness();
        var (admin, _) = await h.NewAdmin();
        (fake == "repo" ? (Faulty)h.Repo : h.Families).Faults[method] = Boom;
        Assert.Same(Boom, await Outcome(() => h.UpdateAdmin.Handle(Update(admin.Id, [Roles.Verifier], null), CancellationToken.None)));
    }

    [Fact]
    public async Task Ensures_a_seeded_admin_once_with_a_known_password()
    {
        var h = new IdentityHarness();
        var ensure = new EnsureSeedAdminHandler(h.AdminUsers);
        await ensure.Handle(new EnsureSeedAdminCommand("super@pao.bd", "Super", [Roles.SuperAdmin], "demo password 123"), CancellationToken.None);
        await ensure.Handle(new EnsureSeedAdminCommand("super@pao.bd", "Super", [Roles.SuperAdmin], "other password 123"), CancellationToken.None);
        Assert.Single(h.Repo.Admins);
        Assert.NotNull(await Login(h, "super@pao.bd", "demo password 123"));
        Assert.Equal(IdentityReasons.RoleInvalid, await Outcome(() => h.AdminUsers.Ensure("x@pao.bd", string.Empty, [Roles.Customer], "p", CancellationToken.None)));
        h.Repo.Faults["AdminByEmail"] = Boom;
        Assert.Same(Boom, await Outcome(() => h.AdminUsers.Ensure("super@pao.bd", "Super", [Roles.SuperAdmin], "p", CancellationToken.None)));
        Assert.True(new EnsureSeedAdminValidator().Validate(new EnsureSeedAdminCommand("a", "b", [], "p")).IsValid);
    }
}
