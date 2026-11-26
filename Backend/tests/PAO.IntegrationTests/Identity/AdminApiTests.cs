using System.Net;
using PAO.Infrastructure.Crypto;

namespace PAO.IntegrationTests.Identity;

public sealed class AdminApiTests(MigratedDatabase database) : IClassFixture<MigratedDatabase>, IAsyncLifetime
{
    private const string NewPassword = "a much longer passphrase 1";
    private IdentityHost api = null!;

    public async ValueTask InitializeAsync() => api = await IdentityHost.Start(database.Url);

    public async ValueTask DisposeAsync() => await api.DisposeAsync();

    [Fact]
    public async Task Refreshes_by_cookie_changes_the_password_and_logs_out_clearing_the_cookie()
    {
        var s = await api.Admin(["super_admin"]);
        var r = await api.Do(HttpMethod.Post, "/v1/auth/refresh", cookie: s.RefreshCookie);
        Assert.Equal(HttpStatusCode.OK, r.Status);
        Assert.False(r.Body.TryGetProperty("refreshToken", out _));
        Assert.Contains("HttpOnly", r.Response.Headers.GetValues("Set-Cookie").Single(), StringComparison.Ordinal);
        var token = r.Text("accessToken");
        var pw = new { currentPassword = s.Password, newPassword = NewPassword };
        Assert.Equal(HttpStatusCode.NoContent, (await api.Do(HttpMethod.Post, "/v1/auth/admin/password", pw, token)).Status);
        Assert.Equal("INVALID_CREDENTIALS", (await api.Do(HttpMethod.Post, "/v1/auth/admin/password", pw, token)).Code);
        var login = await api.Do(HttpMethod.Post, "/v1/auth/admin/login", new { email = s.Email, password = NewPassword });
        Assert.False(login.Body.GetProperty("mustChangePassword").GetBoolean());
        Assert.False(login.Body.TryGetProperty("totpEnrolment", out _));
        var challengeId = login.Text("challengeId");
        Assert.Equal("TOTP_INVALID", (await api.Do(HttpMethod.Post, "/v1/auth/admin/totp", new { challengeId, code = "000000" })).Code);
        var ok = await api.Do(HttpMethod.Post, "/v1/auth/admin/totp", new { challengeId, code = Totp.Code(s.TotpSecret, api.Clock.Now) });
        Assert.Equal(HttpStatusCode.OK, ok.Status);
        var weak = await api.Do(HttpMethod.Post, "/v1/auth/admin/password", new { currentPassword = NewPassword, newPassword = "aaaaaaaaaaaaaaa" }, token);
        Assert.Equal(HttpStatusCode.UnprocessableEntity, weak.Status);
        var output = await api.Do(HttpMethod.Post, "/v1/auth/logout", new { }, token, s.RefreshCookie);
        Assert.Equal(HttpStatusCode.NoContent, output.Status);
        Assert.Contains("Max-Age=0", output.Response.Headers.GetValues("Set-Cookie").Single(), StringComparison.Ordinal);
    }

    [Fact]
    public async Task Locks_out_after_five_wrong_passwords_and_expires_unknown_challenges()
    {
        var s = await api.Admin(["verifier"]);
        Assert.Equal("INVALID_CREDENTIALS", (await api.Do(HttpMethod.Post, "/v1/auth/admin/login", new { email = "nobody@pao.bd", password = "wrong-password" })).Code);
        for (var i = 0; i < 5; i++)
        {
            await api.Do(HttpMethod.Post, "/v1/auth/admin/login", new { email = s.Email, password = "wrong-password" });
        }
        var locked = await api.Do(HttpMethod.Post, "/v1/auth/admin/login", new { email = s.Email, password = s.Password });
        Assert.Equal((HttpStatusCode.TooManyRequests, "ACCOUNT_LOCKED"), (locked.Status, locked.Code));
        var unknown = await api.Do(HttpMethod.Post, "/v1/auth/admin/totp", new { challengeId = Guid.NewGuid(), code = "123456" });
        Assert.Equal("MFA_CHALLENGE_EXPIRED", unknown.Code);
    }

    [Fact]
    public async Task Invites_updates_and_lists_admins_and_edits_roles()
    {
        var admin = await api.Admin(["super_admin"]);
        var token = admin.AccessToken;
        var invite = new { email = "support@pao.bd", name = "Support", roles = new[] { "support_agent" } };
        var r = await api.Do(HttpMethod.Post, "/v1/admin/admin-users", invite, token);
        Assert.Equal(HttpStatusCode.Created, r.Status);
        Assert.NotEqual(string.Empty, r.Text("temporaryPassword"));
        Assert.Equal(HttpStatusCode.Conflict, (await api.Do(HttpMethod.Post, "/v1/admin/admin-users", invite, token)).Status);
        var id = r.Body.GetProperty("user").GetProperty("id").GetString();
        var patch = await api.Do(HttpMethod.Patch, $"/v1/admin/admin-users/{id}", new { active = false, roles = new[] { "verifier" } }, token);
        Assert.False(patch.Body.GetProperty("active").GetBoolean());
        Assert.Equal("verifier", patch.Body.GetProperty("roles")[0].GetString());
        var list = await api.Do(HttpMethod.Get, "/v1/admin/admin-users", token: token);
        var items = list.Body.GetProperty("items");
        Assert.Contains(items.EnumerateArray(), u => u.GetProperty("email").GetString() == "support@pao.bd");
        Assert.Contains(items.EnumerateArray(), u => u.TryGetProperty("lastLoginAt", out _));
        var roles = await api.Do(HttpMethod.Get, "/v1/admin/roles", token: token);
        Assert.Equal(6, roles.Body.GetProperty("items").GetArrayLength());
        var update = new { permissions = new[] { "verification:review", "dashboard:read" }, screens = new[] { "A01", "A05" } };
        Assert.Equal(HttpStatusCode.OK, (await api.Do(HttpMethod.Put, "/v1/admin/roles/verifier", update, token)).Status);
        var bad = new { permissions = new[] { "made:up" }, screens = Array.Empty<string>() };
        Assert.Equal("ROLE_INVALID", (await api.Do(HttpMethod.Put, "/v1/admin/roles/verifier", bad, token)).Code);
        var customer = (await api.SignIn("01812345678", "customer")).GetProperty("accessToken").GetString();
        Assert.Equal(HttpStatusCode.Forbidden, (await api.Do(HttpMethod.Get, "/v1/admin/roles", token: customer)).Status);
        Assert.Equal(HttpStatusCode.NotFound, (await api.Do(HttpMethod.Patch, $"/v1/admin/admin-users/{Guid.NewGuid()}", new { active = true }, token)).Status);
    }

    [Fact]
    public async Task Answers_404_to_a_customer_changing_an_admin_password()
    {
        var customer = (await api.SignIn("01712345670", "customer")).GetProperty("accessToken").GetString();
        var r = await api.Do(HttpMethod.Post, "/v1/auth/admin/password", new { currentPassword = "whatever1", newPassword = NewPassword }, customer);
        Assert.Equal(HttpStatusCode.NotFound, r.Status);
    }

    [Fact]
    public async Task The_seed_creates_a_demo_admin_once_who_can_log_in()
    {
        await api.Admin(["super_admin"], "super@pao.bd");
        var again = await api.Admin(["super_admin"], "super@pao.bd").ContinueWith(t => t.Exception);
        Assert.NotNull(again);
        var r = await api.Do(HttpMethod.Post, "/v1/auth/admin/login", new { email = "super@pao.bd", password = IdentityHost.AdminPassword });
        Assert.False(r.Body.GetProperty("mustChangePassword").GetBoolean());
    }
}
