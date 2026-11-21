using PAO.Core.Areas.Identity.Features.VerifyOtp.Commands;
using PAO.Core.Areas.Identity.Services;
using PAO.Lib.Areas.Identity;
using PAO.Lib.Errors;
using static PAO.UnitTests.Areas.Identity.IdentityHarness;

namespace PAO.UnitTests.Areas.Identity;

/// <summary>SMS_VERIFICATION_ENABLED=false: no SMS, the fixed code, every other rule unchanged.</summary>
public sealed class SmsVerificationOffTests
{
    private static readonly InvalidOperationException Boom = new("boom");

    private static VerifyOtpCommand Verify(string code, string app = "customer") => new(Phone, code, app);

    private static Task<string> SendLogin(IdentityHarness h, string? ip = null) =>
        h.PhoneCodes.Send(Phone, CodePurpose.Login, ip, CancellationToken.None);

    [Fact]
    public async Task Sends_no_sms_and_signs_in_with_the_fixed_code()
    {
        var h = new IdentityHarness(smsVerification: false);
        h.Sms.Faults["Send"] = Boom;
        Assert.Equal(E164, await SendLogin(h));
        Assert.Empty(h.Sms.Last);
        var session = await h.SignIn.Handle(Verify("123456"), CancellationToken.None);
        Assert.True(session.IsNewAccount);
        Assert.Empty(h.Codes.Codes);
    }

    [Fact]
    public async Task Accepts_the_configured_code_only_after_a_request()
    {
        var h = new IdentityHarness(smsVerification: false);
        h.Settings.Sms.FixedCode = "424242";
        Assert.Equal(IdentityReasons.CodeExpired, await Outcome(() => h.SignIn.Handle(Verify("424242"), CancellationToken.None)));
        await SendLogin(h);
        Assert.Equal(IdentityReasons.CodeInvalid, await Outcome(() => h.SignIn.Handle(Verify("123456"), CancellationToken.None)));
        Assert.Equal("resolved", await Outcome(() => h.SignIn.Handle(Verify("424242", "partner"), CancellationToken.None)));
    }

    [Fact]
    public async Task Keeps_the_lockout_the_throttle_and_the_ban()
    {
        var h = new IdentityHarness(smsVerification: false);
        await SendLogin(h);
        for (var i = 1; i < IdentityRules.CodeMaxAttempts; i++)
        {
            Assert.Equal(IdentityReasons.CodeInvalid, await Outcome(() => h.SignIn.Handle(Verify("000000"), CancellationToken.None)));
        }
        Assert.Equal(IdentityReasons.CodeLocked, await Outcome(() => h.SignIn.Handle(Verify("000000"), CancellationToken.None)));
        Assert.Equal(IdentityReasons.CodeExpired, await Outcome(() => h.SignIn.Handle(Verify("123456"), CancellationToken.None)));
        h.Throttle.BlockedIp = "9.9.9.9";
        Assert.Equal(IdentityReasons.RateLimited, await Outcome(() => SendLogin(h, "9.9.9.9")));
        h.Repo.Blocked.Add(E164);
        Assert.Equal(IdentityReasons.AccountBanned, await Outcome(() => SendLogin(h)));
    }

    [Fact]
    public async Task Keeps_codes_bound_to_their_purpose()
    {
        var h = new IdentityHarness(smsVerification: false);
        await h.PhoneCodes.Send(Phone, CodePurpose.EmergencyContact, null, CancellationToken.None);
        Assert.Equal(IdentityReasons.CodeExpired, await Outcome(() => h.SignIn.Handle(Verify("123456"), CancellationToken.None)));
        await h.PhoneCodes.CheckTyped(Phone, CodePurpose.EmergencyContact, "123456");
        Assert.IsType<DomainException>(await Record.ExceptionAsync(() => h.PhoneCodes.CheckTyped(Phone, CodePurpose.EmergencyContact, "123456")));
    }
}
