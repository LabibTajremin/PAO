using PAO.Core.Areas.Identity.Features.RequestOtp.Commands;
using PAO.Core.Areas.Identity.Features.VerifyOtp.Commands;
using PAO.Core.Areas.Identity.Services;
using PAO.Infrastructure.Http.Errors;
using PAO.Lib.Areas.Identity;
using PAO.Lib.Errors;
using static PAO.UnitTests.Areas.Identity.IdentityHarness;

namespace PAO.UnitTests.Areas.Identity;

public sealed class PhoneSignInTests
{
    private static readonly InvalidOperationException Boom = new("boom");

    private static VerifyOtpCommand Verify(string code, string app = "customer", string phone = Phone) => new(phone, code, app);

    [Fact]
    public async Task Creates_the_account_then_adds_the_partner_role_once()
    {
        var h = new IdentityHarness();
        var first = await h.Login("customer");
        Assert.True(first.IsNewAccount);
        Assert.Equal(["customer"], first.Account.Roles);
        Assert.NotEmpty(first.RefreshToken!);
        Assert.IsType<AccountCreated>(h.Repo.Events[0]);
        var second = await h.Login("partner");
        Assert.False(second.IsNewAccount);
        Assert.Equal(first.Account.Id, second.Account.Id);
        Assert.Equal(["customer", "provider"], second.Account.Roles);
        Assert.IsType<RoleGranted>(h.Repo.Events[1]);
        var third = await h.Login("partner");
        Assert.False(third.IsNewAccount);
        Assert.Equal(2, h.Repo.Events.Count);
    }

    [Fact]
    public async Task Locks_a_code_out_after_five_wrong_guesses()
    {
        var h = new IdentityHarness();
        Assert.Equal(IdentityReasons.InvalidPhone, await Outcome(() => h.SignIn.Handle(Verify(string.Empty, phone: "x"), CancellationToken.None)));
        Assert.Equal(IdentityReasons.CodeExpired, await Outcome(() => h.SignIn.Handle(Verify("000000"), CancellationToken.None)));
        await h.PhoneCodes.Send(Phone, CodePurpose.Login, null, CancellationToken.None);
        var wrong = h.SentCode() == "999999" ? "999998" : "999999";
        for (var i = 1; i < IdentityRules.CodeMaxAttempts; i++)
        {
            Assert.Equal(IdentityReasons.CodeInvalid, await Outcome(() => h.SignIn.Handle(Verify(wrong), CancellationToken.None)));
        }
        Assert.Equal(IdentityReasons.CodeLocked, await Outcome(() => h.SignIn.Handle(Verify(wrong), CancellationToken.None)));
        Assert.Empty(h.Codes.Codes);
    }

    [Theory]
    [InlineData("get")]
    [InlineData("increment")]
    [InlineData("malformed hash")]
    public async Task Fails_when_the_code_store_fails(string step)
    {
        var h = new IdentityHarness();
        await h.PhoneCodes.Send(Phone, CodePurpose.Login, null, CancellationToken.None);
        switch (step)
        {
            case "get": h.Codes.Faults["Get"] = Boom; break;
            case "increment": h.Codes.Faults["IncrementAttempts"] = Boom; break;
            default: h.Codes.Codes[$"login:{E164}"] = new StoredCode("bad", 0); break;
        }
        Assert.NotEqual("resolved", await Outcome(() => h.SignIn.Handle(Verify("000000x"), CancellationToken.None)));
    }

    [Theory]
    [InlineData("repo", "AccountByPhone")]
    [InlineData("repo", "CreateAccount")]
    [InlineData("repo", "GrantRole")]
    [InlineData("repo", "Publish")]
    [InlineData("tokens", "Sign")]
    [InlineData("families", "Save")]
    [InlineData("codes", "Delete")]
    public async Task Reports_a_failing_step(string fake, string method)
    {
        var h = new IdentityHarness();
        await h.PhoneCodes.Send(Phone, CodePurpose.Login, null, CancellationToken.None);
        Faulty target = fake switch { "repo" => h.Repo, "tokens" => h.Tokens, "families" => h.Families, _ => h.Codes };
        target.Faults[method] = Boom;
        Assert.Same(Boom, await Outcome(() => h.SignIn.Handle(Verify(h.SentCode()), CancellationToken.None)));
    }

    [Theory]
    [InlineData("GrantRole")]
    [InlineData("Publish")]
    public async Task Reports_a_failing_step_for_a_returning_person(string method)
    {
        var h = new IdentityHarness();
        await h.Login("customer");
        await h.PhoneCodes.Send(Phone, CodePurpose.Login, null, CancellationToken.None);
        h.Repo.Faults[method] = Boom;
        Assert.Same(Boom, await Outcome(() => h.SignIn.Handle(Verify(h.SentCode(), "partner"), CancellationToken.None)));
    }

    [Fact]
    public async Task Refuses_a_banned_account()
    {
        var h = new IdentityHarness();
        var s = await h.Login("customer");
        var id = Guid.Parse(s.Account.Id);
        h.Repo.Accounts[id] = h.Repo.Accounts[id] with { Status = AccountStatus.Banned };
        await h.PhoneCodes.Send(Phone, CodePurpose.Login, null, CancellationToken.None);
        Assert.Equal(IdentityReasons.AccountBanned, await Outcome(() => h.SignIn.Handle(Verify(h.SentCode(), "partner"), CancellationToken.None)));
    }

    [Fact]
    public async Task Refuses_bad_and_blocked_phones_but_sends_other_codes_to_blocked_ones()
    {
        var h = new IdentityHarness();
        Assert.Equal(IdentityReasons.InvalidPhone, await Outcome(() => h.PhoneCodes.Send("123", CodePurpose.Login, null, CancellationToken.None)));
        h.Repo.Blocked.Add(E164);
        Assert.Equal(IdentityReasons.AccountBanned, await Outcome(() => h.PhoneCodes.Send(Phone, CodePurpose.Login, null, CancellationToken.None)));
        Assert.Equal(E164, await h.PhoneCodes.Send(Phone, CodePurpose.DeleteAccount, null, CancellationToken.None));
        h.Repo.Faults["IsPhoneBlocked"] = Boom;
        Assert.Same(Boom, await Outcome(() => h.PhoneCodes.Send(Phone, CodePurpose.Login, null, CancellationToken.None)));
    }

    [Fact]
    public async Task Reports_how_long_to_wait_when_a_window_is_exhausted()
    {
        var h = new IdentityHarness();
        h.Throttle.BlockedIp = "9.9.9.9";
        var error = await Assert.ThrowsAsync<DomainException>(() => h.PhoneCodes.Send(Phone, CodePurpose.Login, "9.9.9.9", CancellationToken.None));
        Assert.Equal(IdentityReasons.RateLimited, error.Reason);
        Assert.Equal(TimeSpan.FromSeconds(42), Assert.IsType<CodeRateLimitedException>(error.InnerException).RetryAfter);
        var api = await Assert.ThrowsAsync<ApiError>(() => new RequestOtpHandler(h.PhoneCodes).Handle(new RequestOtpCommand(Phone, CodePurpose.Login, "9.9.9.9"), CancellationToken.None));
        Assert.Equal(("RATE_LIMITED", TimeSpan.FromSeconds(42)), (api.Code, api.RetryAfter));
    }

    [Theory]
    [InlineData("throttle", "RetryAfter")]
    [InlineData("codes", "Save")]
    [InlineData("sms", "Send")]
    public async Task Reports_a_failing_send(string fake, string method)
    {
        var h = new IdentityHarness();
        Faulty target = fake switch { "throttle" => h.Throttle, "codes" => h.Codes, _ => h.Sms };
        target.Faults[method] = Boom;
        Assert.IsType<InvalidOperationException>(await Outcome(() => h.PhoneCodes.Send(Phone, CodePurpose.Login, null, CancellationToken.None)));
    }

    [Fact]
    public async Task Checks_codes_typed_for_other_purposes()
    {
        var h = new IdentityHarness();
        Assert.Equal(IdentityReasons.InvalidPhone, await Outcome(() => h.PhoneCodes.CheckTyped("bad", CodePurpose.EmergencyContact, "1")));
        await h.PhoneCodes.Send(Phone, CodePurpose.EmergencyContact, null, CancellationToken.None);
        await h.PhoneCodes.CheckTyped(Phone, CodePurpose.EmergencyContact, h.SentCode());
    }

    [Fact]
    public void Validators_accept_the_spec_values()
    {
        Assert.True(new RequestOtpValidator().Validate(new RequestOtpCommand(Phone, CodePurpose.DeleteAccount, string.Empty)).IsValid);
        Assert.False(new RequestOtpValidator().Validate(new RequestOtpCommand(Phone, CodePurpose.EmergencyContact, string.Empty)).IsValid);
        Assert.True(new VerifyOtpValidator().Validate(Verify("123456", "partner")).IsValid);
        Assert.False(new VerifyOtpValidator().Validate(Verify("123456", "admin")).IsValid);
    }
}
