using PAO.Core.Areas.Identity.Features.DeleteMe.Commands;
using PAO.Core.Areas.Identity.Features.GetMe.Queries;
using PAO.Core.Areas.Identity.Features.GetMyPermissions.Queries;
using PAO.Core.Areas.Identity.Features.RoleEditor.Commands;
using PAO.Core.Areas.Identity.Features.SetAccountStatus.Commands;
using PAO.Core.Areas.Identity.Services;
using PAO.Lib.Areas.Identity;
using static PAO.UnitTests.Areas.Identity.IdentityHarness;

namespace PAO.UnitTests.Areas.Identity;

public sealed class AccountTests
{
    private static readonly InvalidOperationException Boom = new("boom");
    private static readonly Guid Actor = Guid.Parse("0199c4f0-0000-7000-8000-000000000009");

    private static Task<AccountRecord> Set(IdentityHarness h, Guid id, string status) =>
        h.Status.Set(new SetAccountStatusInput { AccountId = id, Status = status, Reason = "fraud", ActorId = Actor }, CancellationToken.None);

    private static async Task<string> DeletionCode(IdentityHarness h)
    {
        await h.PhoneCodes.Send(Phone, CodePurpose.DeleteAccount, null, CancellationToken.None);
        return h.SentCode();
    }

    [Fact]
    public async Task Limits_a_merchant_below_level_1_to_the_gate_screens()
    {
        var h = new IdentityHarness();
        var s = await h.Login("customer");
        var me = await new GetMeHandler(h.Repo, h.Mapper).Handle(new GetMeQuery(Guid.Parse(s.Account.Id)), CancellationToken.None);
        Assert.Equal((s.Account.Id, "+8801712345678"), (me.Id, me.Phone));
        var v = await h.Permissions.Handle(PermissionsOf(s.Account.Id), CancellationToken.None);
        Assert.False(v.ProviderGate);
        Assert.Equal(["C01", "C07"], v.Screens);
        await h.Login("partner");
        v = await h.Permissions.Handle(PermissionsOf(s.Account.Id), CancellationToken.None);
        Assert.True(v.ProviderGate);
        Assert.Equal(["C01", "C07", "M01", "M14"], v.Screens);
        h.Levels.Level = 1;
        v = await h.Permissions.Handle(PermissionsOf(s.Account.Id), CancellationToken.None);
        Assert.False(v.ProviderGate);
        Assert.Contains("M15", v.Screens);
        Assert.True(new GetMyPermissionsValidator().Validate(PermissionsOf(s.Account.Id)).IsValid);
        Assert.True(new GetMeValidator().Validate(new GetMeQuery(Guid.NewGuid())).IsValid);
    }

    [Theory]
    [InlineData("repo")]
    [InlineData("rbac")]
    [InlineData("levels")]
    public async Task Reports_a_failing_lookup(string fake)
    {
        var h = new IdentityHarness();
        var s = await h.Login("partner");
        (fake switch { "repo" => (Faulty)h.Repo, "rbac" => h.Rbac, _ => h.Levels }).Faults[fake switch { "repo" => "AccountById", "rbac" => "Of", _ => "GetLevel" }] = Boom;
        Assert.Same(Boom, await Outcome(() => h.Permissions.Handle(PermissionsOf(s.Account.Id), CancellationToken.None)));
    }

    [Fact]
    public async Task Erases_the_account_ends_its_sessions_and_tells_the_other_areas()
    {
        var h = new IdentityHarness();
        var s = await h.Login("customer");
        var caller = h.CallerOf(s);
        await h.Deletion.Handle(Delete(caller, await DeletionCode(h)), CancellationToken.None);
        var a = h.Repo.Accounts[caller.AccountId];
        Assert.Equal((string.Empty, 0), (a.Phone, a.Roles.Count));
        Assert.NotNull(a.DeletedAt);
        Assert.Empty(h.Families.Families);
        Assert.IsType<AccountDeleted>(h.Repo.Events[^1]);
        Assert.Equal(IdentityReasons.AccountDeleted, await Outcome(() => h.Deletion.Handle(Delete(caller, "123456"), CancellationToken.None)));
        Assert.Equal(IdentityReasons.AccountNotFound, await Outcome(() => h.Deletion.Handle(Delete(caller with { AccountId = Guid.NewGuid() }, "1"), CancellationToken.None)));
        Assert.True(new DeleteMeValidator().Validate(Delete(caller, "1")).IsValid);
    }

    [Theory]
    [InlineData("SetRoles")]
    [InlineData("AnonymiseAccount")]
    [InlineData("code")]
    public async Task Fails_the_deletion_when_a_step_fails(string step)
    {
        var h = new IdentityHarness();
        var s = await h.Login("customer");
        var code = step == "code" ? "x" : await DeletionCode(h);
        h.Repo.Faults[step] = Boom;
        Assert.NotEqual("resolved", await Outcome(() => h.Deletion.Handle(Delete(h.CallerOf(s), code), CancellationToken.None)));
        // Sessions end even when erasing failed: the person asked to be signed out.
        Assert.Equal(step == "code", h.Families.Families.Count > 0);
    }

    [Fact]
    public async Task Bans_reinstates_and_suspends()
    {
        var h = new IdentityHarness();
        var id = Guid.Parse((await h.Login("customer")).Account.Id);
        Assert.Equal(AccountStatus.Banned, (await Set(h, id, AccountStatus.Banned)).Status);
        Assert.Contains(E164, h.Repo.Blocked);
        Assert.Empty(h.Families.Families);
        var changed = Assert.IsType<AccountStatusChanged>(h.Repo.Events[^1]);
        Assert.Equal((AccountStatus.Active, AccountStatus.Banned, (Guid?)Actor, "customer"), (changed.From, changed.To, changed.ActorId, changed.Roles.Single()));
        await Set(h, id, AccountStatus.Active);
        Assert.DoesNotContain(E164, h.Repo.Blocked);
        Assert.Equal(IdentityReasons.StatusChange, await Outcome(() => Set(h, id, AccountStatus.Active)));
        Assert.Equal(AccountStatus.Suspended, (await Set(h, id, AccountStatus.Suspended)).Status);
        var contract = await new SetAccountStatusHandler(h.Status, h.Mapper).Handle(
            new SetAccountStatusCommand(new SetAccountStatusInput { AccountId = id, Status = AccountStatus.Active, Reason = "appeal" }), CancellationToken.None);
        Assert.Equal(AccountStatus.Active, contract.Status);
        Assert.True(new SetAccountStatusValidator().Validate(new SetAccountStatusCommand(new SetAccountStatusInput { AccountId = id, Status = "x", Reason = "y" })).IsValid);
    }

    [Fact]
    public async Task Bans_an_admin_who_has_no_phone()
    {
        var h = new IdentityHarness();
        var invited = await h.NewAdmin();
        Assert.Equal(AccountStatus.Banned, (await Set(h, invited.Admin.Id, AccountStatus.Banned)).Status);
    }

    [Theory]
    [InlineData("AccountById", AccountStatus.Banned)]
    [InlineData("UpdateStatus", AccountStatus.Banned)]
    [InlineData("BlockPhone", AccountStatus.Banned)]
    [InlineData("Publish", AccountStatus.Banned)]
    [InlineData("ListForAccount", AccountStatus.Banned)]
    [InlineData("UnblockPhone", AccountStatus.Active)]
    public async Task Fails_the_status_change_when_a_step_fails(string step, string to)
    {
        var h = new IdentityHarness();
        var id = Guid.Parse((await h.Login("customer")).Account.Id);
        if (to == AccountStatus.Active)
        {
            await Set(h, id, AccountStatus.Banned);
        }
        h.Repo.Faults[step] = Boom;
        h.Families.Faults[step] = Boom;
        Assert.Same(Boom, await Outcome(() => Set(h, id, to)));
    }

    [Fact]
    public async Task Lists_roles_and_replaces_grants_bumping_the_rbac_version()
    {
        var h = new IdentityHarness();
        var c = await h.ListRoles.Handle(RolesQuery, CancellationToken.None);
        Assert.Equal((3, 3, 7), (c.Items.Count, c.AllPermissions.Count, c.AllScreens.Count));
        var def = await h.UpdateRole.Handle(Role("verifier", ["verification:review", "job:respond"], ["A05"]), CancellationToken.None);
        Assert.Equal("verifier", def.Role);
        Assert.Equal(1, h.Rbac.Version);
        Assert.Equal(2, h.Repo.Grants["verifier"].Permissions.Count);
        foreach (var bad in new[] { Role("nobody", [], []), Role("verifier", ["made:up"], []), Role("verifier", [], ["Z99"]) })
        {
            Assert.Equal(IdentityReasons.RoleInvalid, await Outcome(() => h.UpdateRole.Handle(bad, CancellationToken.None)));
        }
        Assert.True(new UpdateRoleValidator().Validate(Role("verifier", [], [])).IsValid);
    }

    [Theory]
    [InlineData("ListRoles")]
    [InlineData("AllGrants")]
    [InlineData("Catalogue")]
    public async Task Fails_to_list_when_a_read_fails(string step)
    {
        var h = new IdentityHarness();
        h.Repo.Faults[step] = Boom;
        Assert.Same(Boom, await Outcome(() => h.ListRoles.Handle(RolesQuery, CancellationToken.None)));
    }

    [Theory]
    [InlineData("ListRoles")]
    [InlineData("Catalogue")]
    [InlineData("ReplaceRole")]
    [InlineData("BumpVersion")]
    public async Task Fails_to_update_when_a_step_fails(string step)
    {
        var h = new IdentityHarness();
        h.Repo.Faults[step] = Boom;
        h.Rbac.Faults[step] = Boom;
        Assert.Same(Boom, await Outcome(() => h.UpdateRole.Handle(Role("verifier", [], []), CancellationToken.None)));
    }
}
