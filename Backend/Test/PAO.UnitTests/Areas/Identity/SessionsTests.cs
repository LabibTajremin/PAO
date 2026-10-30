using PAO.Core.Areas.Identity.Features.Logout.Commands;
using PAO.Core.Areas.Identity.Features.RefreshToken.Commands;
using PAO.Core.Areas.Identity.Services;
using PAO.Lib.Areas.Identity;
using PAO.Lib.Errors;
using static PAO.UnitTests.Areas.Identity.IdentityHarness;

namespace PAO.UnitTests.Areas.Identity;

public sealed class SessionsTests
{
    private static readonly InvalidOperationException Boom = new("boom");

    [Fact]
    public async Task Rotates_the_refresh_token_and_revokes_the_family_on_reuse()
    {
        var h = new IdentityHarness();
        var s = await h.Login("customer");
        var next = await new RefreshTokenHandler(h.Sessions, h.Mapper).Handle(new RefreshTokenCommand(s.RefreshToken!, false), CancellationToken.None);
        Assert.NotEqual(s.RefreshToken, next.View.RefreshToken);
        Assert.Equal(next.RefreshToken, next.View.RefreshToken);
        var cookie = await new RefreshTokenHandler(h.Sessions, h.Mapper).Handle(new RefreshTokenCommand(next.RefreshToken, true), CancellationToken.None);
        Assert.Null(cookie.View.RefreshToken);
        Assert.Equal(IdentityReasons.RefreshReused, await Outcome(() => h.Sessions.Refresh(s.RefreshToken!, CancellationToken.None)));
        Assert.Empty(h.Families.Families);
        Assert.Single(h.Tokens.Denied);
        Assert.Equal(IdentityReasons.RefreshInvalid, await Outcome(() => h.Sessions.Refresh(cookie.RefreshToken, CancellationToken.None)));
    }

    [Fact]
    public async Task Refuses_garbage_lookup_failures_and_suspended_accounts()
    {
        var h = new IdentityHarness();
        Assert.Equal(IdentityReasons.RefreshInvalid, await Outcome(() => h.Sessions.Refresh("garbage", CancellationToken.None)));
        var s = await h.Login("customer");
        h.Repo.Faults["AccountById"] = Boom;
        Assert.Same(Boom, await Outcome(() => h.Sessions.Refresh(s.RefreshToken!, CancellationToken.None)));
        h.Repo.Faults.Clear();
        var id = Guid.Parse(s.Account.Id);
        h.Repo.Accounts[id] = h.Repo.Accounts[id] with { Status = AccountStatus.Suspended };
        Assert.Equal(IdentityReasons.AccountSuspended, await Outcome(() => h.Sessions.Refresh(s.RefreshToken!, CancellationToken.None)));
        Assert.Empty(h.Families.Families);
    }

    [Fact]
    public async Task Logs_out_one_device_or_all_of_them()
    {
        var h = new IdentityHarness();
        var caller = h.CallerOf(await h.Login("customer"));
        await h.Login("customer");
        var logout = new LogoutHandler(h.Sessions);
        await logout.Handle(new LogoutCommand(caller, false), CancellationToken.None);
        Assert.Single(h.Families.Families);
        await logout.Handle(new LogoutCommand(caller with { SessionId = Guid.NewGuid() }, false), CancellationToken.None);
        var other = h.Families.Families.Values.Single();
        await logout.Handle(new LogoutCommand(caller with { SessionId = other.Id }, true), CancellationToken.None);
        Assert.Empty(h.Families.Families);
        Assert.True(new LogoutValidator().Validate(new LogoutCommand(caller, true)).IsValid);
    }

    [Theory]
    [InlineData("tokens", "Revoke")]
    [InlineData("families", "Get")]
    [InlineData("families", "ListForAccount")]
    [InlineData("families", "Delete")]
    public async Task Reports_a_failing_step_on_logout(string fake, string method)
    {
        var h = new IdentityHarness();
        var caller = h.CallerOf(await h.Login("customer"));
        Faulty target = fake == "tokens" ? h.Tokens : h.Families;
        target.Faults[method] = Boom;
        var one = await Outcome(() => h.Sessions.Logout(caller, false));
        var all = await Outcome(() => h.Sessions.Logout(caller, true));
        Assert.Contains(Boom, new[] { one, all });
    }

    [Fact]
    public async Task Keeps_the_refusal_when_ending_a_reused_family_fails()
    {
        var h = new IdentityHarness();
        var s = await h.Login("customer");
        await h.Sessions.Refresh(s.RefreshToken!, CancellationToken.None);
        h.Tokens.Faults["Revoke"] = Boom;
        var error = await Assert.ThrowsAsync<DomainException>(() => h.Sessions.Refresh(s.RefreshToken!, CancellationToken.None));
        Assert.Equal(IdentityReasons.RefreshReused, error.Reason);
        Assert.Same(Boom, error.InnerException);
        Assert.True(new RefreshTokenValidator().Validate(new RefreshTokenCommand(string.Empty, true)).IsValid);
    }
}
