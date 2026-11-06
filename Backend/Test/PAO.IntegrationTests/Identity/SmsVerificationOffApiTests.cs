using System.Net;
using Microsoft.Extensions.DependencyInjection;
using PAO.Infrastructure.Testing;
using PAO.Lib.Areas.Identity;

namespace PAO.IntegrationTests.Identity;

/// <summary>The API with SMS_VERIFICATION_ENABLED=false: no SMS, the fixed code signs in, the limits hold.</summary>
public sealed class SmsVerificationOffApiTests(MigratedDatabase database) : IClassFixture<MigratedDatabase>, IAsyncLifetime
{
    private readonly string phone = "019" + Random.Shared.Next(10_000_000, 99_999_999);
    private IdentityHost api = null!;

    public async ValueTask InitializeAsync() => api = await IdentityHost.Start(database.Url, smsVerification: false);

    public async ValueTask DisposeAsync() => await api.DisposeAsync();

    private Task<Answer> Verify(string code) => api.Do(HttpMethod.Post, "/v1/auth/otp/verify", new { phone, code, app = "partner" });

    [Fact]
    public async Task Signs_in_with_the_fixed_code_without_sending_an_sms()
    {
        Assert.Equal("OTP_EXPIRED", (await Verify("123456")).Code);
        var sent = await api.Do(HttpMethod.Post, "/v1/auth/otp/request", new { phone });
        Assert.Equal(HttpStatusCode.Accepted, sent.Status);
        Assert.Null(api.App.Services.GetRequiredService<ISmsCapture>().Last(PhoneNumber.Normalize(phone)!));
        var again = await api.Do(HttpMethod.Post, "/v1/auth/otp/request", new { phone });
        Assert.Equal((HttpStatusCode.TooManyRequests, "RATE_LIMITED"), (again.Status, again.Code));
        var wrong = await Verify("654321");
        Assert.Equal((HttpStatusCode.Unauthorized, "OTP_INVALID"), (wrong.Status, wrong.Code));
        var verified = await Verify("123456");
        Assert.Equal(HttpStatusCode.OK, verified.Status);
        Assert.Equal("provider", verified.Body.GetProperty("account").GetProperty("roles")[0].GetString());
    }
}
