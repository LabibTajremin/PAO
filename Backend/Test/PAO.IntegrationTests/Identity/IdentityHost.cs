using System.Net;
using System.Text.Json;
using Microsoft.AspNetCore.Builder;
using Microsoft.AspNetCore.TestHost;
using Microsoft.Extensions.DependencyInjection;
using Microsoft.Extensions.DependencyInjection.Extensions;
using PAO.Core.Areas.Identity.Features.AdminUsers.Commands;
using PAO.Core.Areas.Verification.Services.Shared;
using PAO.Infrastructure.Crypto;
using PAO.Infrastructure.Data;
using PAO.Infrastructure.Testing;
using PAO.Lib.Areas.Identity;
using PAO.Lib.Areas.Verification;
using PAO.Lib.Mediator;
using PAO.TestKit;

namespace PAO.IntegrationTests.Identity;

/// <summary>Verification is not ported yet; merchants are at the level the test sets.</summary>
public sealed class FixedLevels : IVerificationSharedService
{
    public int Level { get; set; }

    public Task<int> GetLevel(Guid merchantId, CancellationToken cancellationToken) => Task.FromResult(Level);

    public Task<IReadOnlyDictionary<Guid, int>> GetLevels(IReadOnlyCollection<Guid> merchantIds, CancellationToken cancellationToken) => throw new NotSupportedException();

    public Task<bool> CanReceiveBookings(Guid merchantId, Guid? serviceId, CancellationToken cancellationToken) => throw new NotSupportedException();

    public Task<IReadOnlyList<VerificationItem>> GetItems(Guid merchantId, CancellationToken cancellationToken) => throw new NotSupportedException();

    public Task<int> CountPendingReviews(CancellationToken cancellationToken) => throw new NotSupportedException();
}

public sealed record Answer(HttpStatusCode Status, JsonElement Body, HttpResponseMessage Response)
{
    public string? Code => Body.ValueKind == JsonValueKind.Object && Body.TryGetProperty("error", out var e) ? e.GetProperty("code").GetString() : null;

    public string Text(string name) => Body.GetProperty(name).GetString()!;
}

public sealed record AdminSession(Guid Id, string Email, string Password, string TotpSecret, string AccessToken, string RefreshCookie);

/// <summary>An API on a test server with a movable clock and helpers for the identity flows.</summary>
public sealed class IdentityHost : IAsyncDisposable
{
    public const string AdminPassword = "demo password 123";

    private IdentityHost(WebApplication app, FakeClock clock)
    {
        App = app;
        Clock = clock;
        Client = app.GetTestClient();
    }

    public WebApplication App { get; }
    public FakeClock Clock { get; }
    public HttpClient Client { get; }
    public FixedLevels Levels => App.Services.GetRequiredService<FixedLevels>();

    public static async Task<IdentityHost> Start(string databaseUrl)
    {
        var clock = new FakeClock(DateTimeOffset.UtcNow);
        var app = await Hosts.Api(databaseUrl, configure: services =>
        {
            services.Replace(ServiceDescriptor.Singleton<IClock>(clock));
            services.AddSingleton<FixedLevels>();
            services.AddSingleton<IVerificationSharedService>(sp => sp.GetRequiredService<FixedLevels>());
        });
        return new IdentityHost(app, clock);
    }

    public ValueTask DisposeAsync() => App.DisposeAsync();

    public async Task<Answer> Do(HttpMethod method, string path, object? body = null, string? token = null, string? cookie = null)
    {
        using var request = Hosts.Request(method, path, token, body);
        if (cookie is not null)
        {
            request.Headers.Add("Cookie", cookie);
        }
        var response = await Client.SendAsync(request);
        var text = await response.Content.ReadAsStringAsync();
        var json = text.Length == 0 ? default : JsonDocument.Parse(text).RootElement.Clone();
        return new Answer(response.StatusCode, json, response);
    }

    public string LastCode(string phone)
    {
        var message = App.Services.GetRequiredService<ISmsCapture>().Last(PhoneNumber.Normalize(phone)!)!;
        return message.Split("code: ")[1][..6];
    }

    public async Task<JsonElement> SignIn(string phone, string app)
    {
        var sent = await Do(HttpMethod.Post, "/v1/auth/otp/request", new { phone });
        Assert.Equal(HttpStatusCode.Accepted, sent.Status);
        var verified = await Do(HttpMethod.Post, "/v1/auth/otp/verify", new { phone, code = LastCode(phone), app });
        Assert.Equal(HttpStatusCode.OK, verified.Status);
        return verified.Body;
    }

    /// <summary>Signs in again after the resend window.</summary>
    public Task<JsonElement> SignInAgain(string phone, string app)
    {
        Clock.Advance(TimeSpan.FromMinutes(1));
        return SignIn(phone, app);
    }

    public async Task<AdminSession> Admin(string[] roles, string? email = null)
    {
        email ??= $"admin-{Guid.NewGuid():N}@pao.bd";
        using (var scope = App.Services.CreateScope())
        {
            await scope.ServiceProvider.GetRequiredService<IMediator>().Send(new EnsureSeedAdminCommand(email, "Admin", roles, AdminPassword));
        }
        var login = await Do(HttpMethod.Post, "/v1/auth/admin/login", new { email, password = AdminPassword });
        var secret = login.Body.GetProperty("totpEnrolment").GetProperty("secret").GetString()!;
        var totp = await Do(HttpMethod.Post, "/v1/auth/admin/totp", new { challengeId = login.Text("challengeId"), code = Totp.Code(secret, Clock.Now) });
        var cookie = totp.Response.Headers.GetValues("Set-Cookie").Single().Split(';')[0];
        var account = totp.Body.GetProperty("account");
        return new AdminSession(Guid.Parse(account.GetProperty("id").GetString()!), email, AdminPassword, secret, totp.Text("accessToken"), cookie);
    }

}
