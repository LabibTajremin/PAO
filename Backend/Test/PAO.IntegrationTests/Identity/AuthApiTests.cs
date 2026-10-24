using System.Net;
using Microsoft.Extensions.DependencyInjection;
using PAO.Core.Areas.Identity.Services.Shared;
using PAO.Lib.Areas.Identity;

namespace PAO.IntegrationTests.Identity;

public sealed class AuthApiTests(MigratedDatabase database) : IClassFixture<MigratedDatabase>, IAsyncLifetime
{
    private IdentityHost api = null!;
    private string phone = null!;

    public async ValueTask InitializeAsync()
    {
        api = await IdentityHost.Start(database.Url);
        // Tests share the database, so each signs in with its own number.
        phone = "017" + Random.Shared.Next(10_000_000, 99_999_999);
    }

    public async ValueTask DisposeAsync() => await api.DisposeAsync();

    [Fact]
    public async Task Signs_in_by_otp_refreshes_detects_reuse_and_logs_out()
    {
        var tp = await api.SignIn(phone, "customer");
        Assert.True(tp.GetProperty("isNewAccount").GetBoolean());
        Assert.Equal("customer", tp.GetProperty("account").GetProperty("roles")[0].GetString());
        var token = tp.GetProperty("accessToken").GetString()!;
        var me = await api.Do(HttpMethod.Get, "/v1/me", token: token);
        Assert.Equal(PhoneNumber.Normalize(phone), me.Text("phone"));
        Assert.False(me.Body.TryGetProperty("email", out _));
        var refresh = tp.GetProperty("refreshToken").GetString()!;
        var next = await api.Do(HttpMethod.Post, "/v1/auth/refresh", new { refreshToken = refresh });
        Assert.Equal(HttpStatusCode.OK, next.Status);
        Assert.NotEqual(refresh, next.Text("refreshToken"));
        var reuse = await api.Do(HttpMethod.Post, "/v1/auth/refresh", new { refreshToken = refresh });
        Assert.Equal((HttpStatusCode.Unauthorized, "REFRESH_TOKEN_INVALID"), (reuse.Status, reuse.Code));
        Assert.Equal(HttpStatusCode.Unauthorized, (await api.Do(HttpMethod.Post, "/v1/auth/refresh", new { refreshToken = next.Text("refreshToken") })).Status);
        var fresh = (await api.SignInAgain(phone, "customer")).GetProperty("accessToken").GetString()!;
        Assert.Equal(HttpStatusCode.NoContent, (await api.Do(HttpMethod.Post, "/v1/auth/logout", new { allDevices = false }, fresh)).Status);
        Assert.Equal(HttpStatusCode.Unauthorized, (await api.Do(HttpMethod.Get, "/v1/me", token: fresh)).Status);
        Assert.Equal(HttpStatusCode.Unauthorized, (await api.Do(HttpMethod.Post, "/v1/auth/refresh")).Status);
    }

    [Fact]
    public async Task Validates_phones_throttles_resends_and_locks_out_wrong_codes()
    {
        Assert.Equal(HttpStatusCode.UnprocessableEntity, (await api.Do(HttpMethod.Post, "/v1/auth/otp/request", new { phone = "123" })).Status);
        var first = await api.Do(HttpMethod.Post, "/v1/auth/otp/request", new { phone });
        Assert.Equal(300, first.Body.GetProperty("expiresInSeconds").GetInt32());
        Assert.Equal(60, first.Body.GetProperty("resendAfterSeconds").GetInt32());
        var again = await api.Do(HttpMethod.Post, "/v1/auth/otp/request", new { phone });
        Assert.Equal((HttpStatusCode.TooManyRequests, "RATE_LIMITED"), (again.Status, again.Code));
        Assert.NotNull(again.Response.Headers.RetryAfter);
        var code = api.LastCode(phone);
        var wrong = code == "000000" ? "111111" : "000000";
        Task<Answer> Verify(string p, string c) => api.Do(HttpMethod.Post, "/v1/auth/otp/verify", new { phone = p, code = c, app = "customer" });
        var invalid = await Verify(phone, wrong);
        Assert.Equal((HttpStatusCode.Unauthorized, "OTP_INVALID"), (invalid.Status, invalid.Code));
        Assert.Equal("OTP_EXPIRED", (await Verify("01812345670", "123456")).Code);
        for (var i = 0; i < 3; i++)
        {
            await Verify(phone, wrong);
        }
        var locked = await Verify(phone, wrong);
        Assert.Equal((HttpStatusCode.TooManyRequests, "OTP_LOCKED"), (locked.Status, locked.Code));
        Assert.Equal("300", locked.Response.Headers.GetValues("Retry-After").Single());
        Assert.Equal("OTP_EXPIRED", (await Verify(phone, code)).Code);
    }

    [Fact]
    public async Task Gates_a_level_0_merchant_to_the_onboarding_screens()
    {
        var token = (await api.SignIn(phone, "partner")).GetProperty("accessToken").GetString()!;
        var r = await api.Do(HttpMethod.Get, "/v1/me/permissions", token: token);
        Assert.True(r.Body.GetProperty("providerGate").GetBoolean());
        Assert.Equal("provider", r.Body.GetProperty("roles")[0].GetString());
        Assert.Equal(14, r.Body.GetProperty("screens").GetArrayLength());
        api.Levels.Level = 1;
        var verified = await api.Do(HttpMethod.Get, "/v1/me/permissions", token: token);
        Assert.False(verified.Body.GetProperty("providerGate").GetBoolean());
        Assert.True(verified.Body.GetProperty("screens").GetArrayLength() > 14);
    }

    [Fact]
    public async Task Shuts_a_banned_account_out()
    {
        var tp = await api.SignIn(phone, "customer");
        var token = tp.GetProperty("accessToken").GetString()!;
        using (var scope = api.App.Services.CreateScope())
        {
            await scope.ServiceProvider.GetRequiredService<IIdentitySharedService>().SetAccountStatus(new SetAccountStatusInput
            {
                AccountId = Guid.Parse(tp.GetProperty("account").GetProperty("id").GetString()!),
                Status = AccountStatus.Banned,
                Reason = "fraud",
            }, CancellationToken.None);
        }
        Assert.Equal(HttpStatusCode.Unauthorized, (await api.Do(HttpMethod.Get, "/v1/me", token: token)).Status);
        var refresh = await api.Do(HttpMethod.Post, "/v1/auth/refresh", new { refreshToken = tp.GetProperty("refreshToken").GetString() });
        Assert.Equal(HttpStatusCode.Unauthorized, refresh.Status);
        var code = await api.Do(HttpMethod.Post, "/v1/auth/otp/request", new { phone });
        Assert.Equal((HttpStatusCode.Forbidden, "ACCOUNT_BANNED"), (code.Status, code.Code));
    }

    [Fact]
    public async Task Deletes_the_account_after_a_fresh_code()
    {
        var tp = await api.SignIn(phone, "customer");
        var token = tp.GetProperty("accessToken").GetString()!;
        api.Clock.Advance(TimeSpan.FromMinutes(1));
        var sent = await api.Do(HttpMethod.Post, "/v1/auth/otp/request", new { phone, purpose = "delete_account" });
        Assert.Equal(HttpStatusCode.Accepted, sent.Status);
        Assert.Equal(HttpStatusCode.NoContent, (await api.Do(HttpMethod.Delete, "/v1/me", new { code = api.LastCode(phone) }, token)).Status);
        Assert.Equal(HttpStatusCode.Unauthorized, (await api.Do(HttpMethod.Get, "/v1/me", token: token)).Status);
        var refresh = await api.Do(HttpMethod.Post, "/v1/auth/refresh", new { refreshToken = tp.GetProperty("refreshToken").GetString() });
        Assert.Equal(HttpStatusCode.Unauthorized, refresh.Status);
    }

    [Fact]
    public async Task Answers_a_role_less_account_and_a_deletion_without_a_code()
    {
        var tp = await api.SignIn(phone, "customer");
        var token = tp.GetProperty("accessToken").GetString()!;
        await using (var connection = await PAO.TestKit.TestDatabases.Open(database.Url))
        {
            await PAO.TestKit.TestDatabases.Execute(connection, $"DELETE FROM identity.account_roles WHERE account_id = '{tp.GetProperty("account").GetProperty("id").GetString()}'");
        }
        var r = await api.Do(HttpMethod.Get, "/v1/me/permissions", token: token);
        Assert.Equal(0, r.Body.GetProperty("permissions").GetArrayLength());
        Assert.Equal(0, r.Body.GetProperty("screens").GetArrayLength());
        Assert.Equal("OTP_EXPIRED", (await api.Do(HttpMethod.Delete, "/v1/me", new { code = "123456" }, token)).Code);
    }
}
