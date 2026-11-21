using System.Net;
using Microsoft.Extensions.DependencyInjection;
using PAO.Core.Areas.Identity.Services.Shared;
using PAO.Infrastructure.Redis;
using PAO.Lib.Areas.Identity;
using PAO.Lib.Errors;
using PAO.TestKit;
using StackExchange.Redis;

namespace PAO.IntegrationTests.Identity;

public sealed class IdentityEdgeTests : IAsyncLifetime
{
    private const string Phone = "01712345678";
    private string url = string.Empty;
    private IdentityHost api = null!;

    public async ValueTask InitializeAsync()
    {
        url = await TestDatabases.CreateMigrated();
        api = await IdentityHost.Start(url);
    }

    public async ValueTask DisposeAsync()
    {
        await api.DisposeAsync();
        await TestDatabases.Drop(url);
    }

    private static async Task<string?> Reason(Func<Task> call)
    {
        try
        {
            await call();
            return null;
        }
        catch (DomainException error)
        {
            return error.Reason;
        }
    }

    [Fact]
    public async Task The_shared_contract_reads_accounts_changes_status_and_checks_other_purpose_codes()
    {
        using var scope = api.App.Services.CreateScope();
        var c = scope.ServiceProvider.GetRequiredService<IIdentitySharedService>();
        var tp = await api.SignIn(Phone, "customer");
        var id = Guid.Parse(tp.GetProperty("account").GetProperty("id").GetString()!);
        var account = await c.GetAccount(id, CancellationToken.None);
        Assert.Equal(("+8801712345678", AccountStatus.Active), (account.Phone, account.Status));
        Assert.Equal(["customer"], account.Roles);
        Assert.False(await c.HasRole(id, Roles.Provider, CancellationToken.None));
        Assert.Equal(IdentityErrors.AccountNotFound, await Reason(() => c.GetAccount(Guid.NewGuid(), CancellationToken.None)));
        Assert.Equal(IdentityErrors.AccountNotFound, await Reason(() => c.HasRole(Guid.NewGuid(), Roles.Provider, CancellationToken.None)));
        Task Set(string status) => c.SetAccountStatus(new SetAccountStatusInput { AccountId = id, Status = status, Reason = "appeal" }, CancellationToken.None);
        Assert.Equal(IdentityErrors.StatusInvalid, await Reason(() => Set(AccountStatus.Active)));
        await Set(AccountStatus.Banned);
        Assert.Null(await Reason(() => Set(AccountStatus.Active)));
        await c.SendPhoneCode("01912345678", CodePurpose.EmergencyContact, CancellationToken.None);
        Assert.Equal(IdentityErrors.CodeInvalid, await Reason(() => c.CheckPhoneCode("01912345678", CodePurpose.EmergencyContact, "x", CancellationToken.None)));
        await c.CheckPhoneCode("01912345678", CodePurpose.EmergencyContact, api.LastCode("01912345678"), CancellationToken.None);
    }

    [Fact]
    public async Task Answers_500_when_a_session_entry_is_corrupt()
    {
        var tp = await api.SignIn(Phone, "customer");
        var sid = Guid.NewGuid();
        var keys = api.App.Services.GetRequiredService<RedisKeys>();
        await api.App.Services.GetRequiredService<IConnectionMultiplexer>().GetDatabase().StringSetAsync(keys.Key("rt", sid.ToString()), "not-a-hash");
        var subject = tp.GetProperty("account").GetProperty("id").GetString()!;
        var token = api.App.Services.GetRequiredService<PAO.Infrastructure.Crypto.TokenSigner>()
            .Sign(new PAO.Infrastructure.Crypto.TokenRequest(subject, ["customer"], sid.ToString())).Token;
        Assert.Equal(HttpStatusCode.InternalServerError, (await api.Do(HttpMethod.Post, "/v1/auth/logout", new { }, token)).Status);
    }

    [Fact]
    public async Task Answers_500_when_the_database_is_gone()
    {
        var admin = await api.Admin(["super_admin"]);
        var customer = (await api.SignIn(Phone, "customer")).GetProperty("accessToken").GetString();
        // Warm the RBAC cache so authorisation passes and the handlers meet the failure.
        await api.Do(HttpMethod.Get, "/v1/admin/roles", token: admin.AccessToken);
        await TestDatabases.Drop(url);
        (HttpMethod, string, string?, object?)[] calls =
        [
            (HttpMethod.Get, "/v1/me", customer, null),
            (HttpMethod.Get, "/v1/me/permissions", customer, null),
            (HttpMethod.Delete, "/v1/me", customer, new { code = "123456" }),
            (HttpMethod.Get, "/v1/admin/admin-users", admin.AccessToken, null),
            (HttpMethod.Post, "/v1/admin/admin-users", admin.AccessToken, new { email = "x@pao.bd", name = "Xavier", roles = new[] { "verifier" } }),
            (HttpMethod.Patch, $"/v1/admin/admin-users/{admin.Id}", admin.AccessToken, new { active = true }),
            (HttpMethod.Get, "/v1/admin/roles", admin.AccessToken, null),
            (HttpMethod.Put, "/v1/admin/roles/verifier", admin.AccessToken, new { permissions = Array.Empty<string>(), screens = Array.Empty<string>() }),
            (HttpMethod.Post, "/v1/auth/admin/login", null, new { email = admin.Email, password = "whatever12" }),
            (HttpMethod.Post, "/v1/auth/admin/password", admin.AccessToken, new { currentPassword = "whatever12", newPassword = "a much longer passphrase 1" }),
        ];
        foreach (var (method, path, token, body) in calls)
        {
            Assert.Equal((method, path, HttpStatusCode.InternalServerError), (method, path, (await api.Do(method, path, body, token)).Status));
        }
    }

    [Fact]
    public async Task Answers_500_when_redis_is_gone()
    {
        var customer = (await api.SignIn(Phone, "customer")).GetProperty("accessToken").GetString();
        await api.App.Services.GetRequiredService<IConnectionMultiplexer>().CloseAsync();
        Assert.Equal(HttpStatusCode.InternalServerError, (await api.Do(HttpMethod.Post, "/v1/auth/logout", new { }, customer)).Status);
        Assert.Equal(HttpStatusCode.InternalServerError, (await api.Do(HttpMethod.Get, "/v1/me", token: customer)).Status);
        var body = new { phone = Phone, code = "123456", app = "customer", refreshToken = $"{Guid.NewGuid()}.x", challengeId = Guid.NewGuid() };
        foreach (var path in new[] { "otp/request", "otp/verify", "refresh", "admin/totp" })
        {
            Assert.Equal((path, HttpStatusCode.InternalServerError), (path, (await api.Do(HttpMethod.Post, $"/v1/auth/{path}", body)).Status));
        }
    }
}
