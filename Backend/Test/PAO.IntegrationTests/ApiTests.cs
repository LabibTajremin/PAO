using System.Net;
using System.Text.Json;
using Microsoft.AspNetCore.Builder;
using Microsoft.AspNetCore.TestHost;
using Microsoft.Extensions.DependencyInjection;
using PAO.Infrastructure.Crypto;
using PAO.Infrastructure.Redis;
using PAO.Infrastructure.Sms;
using PAO.Lib.Mediator;
using PAO.TestKit;

namespace PAO.IntegrationTests;

public sealed class ApiTests(MigratedDatabase database) : IClassFixture<MigratedDatabase>, IAsyncLifetime
{
    private WebApplication app = null!;
    private HttpClient client = null!;

    public async ValueTask InitializeAsync()
    {
        app = await Hosts.Api(database.Url, configure: s => s.AddSingleton<EdgeTestRoutes>());
        client = app.GetTestClient();
    }

    public async ValueTask DisposeAsync() => await app.DisposeAsync();

    private static object Booking(string note) => new
    {
        providerId = Guid.NewGuid(),
        serviceId = Guid.NewGuid(),
        addressId = Guid.NewGuid(),
        timing = "asap",
        note,
        items = new[] { new { subServiceId = Guid.NewGuid(), quantity = 1 } },
    };

    [Fact]
    public async Task Health_and_readiness_answer_outside_the_contract()
    {
        Assert.Equal("{\"status\":\"ok\"}", await client.GetStringAsync("/healthz"));
        var ready = await client.GetAsync("/readyz");
        Assert.Equal(HttpStatusCode.OK, ready.StatusCode);
        Assert.Equal(HttpStatusCode.MethodNotAllowed, (await client.PostAsync("/healthz", null)).StatusCode);
    }

    [Fact]
    public async Task Unknown_routes_and_methods_are_rejected_before_controllers()
    {
        var missing = await client.GetAsync("/v1/nothing-here");
        Assert.Equal(HttpStatusCode.NotFound, missing.StatusCode);
        Assert.Equal("NOT_FOUND", await Hosts.ErrorCode(missing));
        Assert.Equal(HttpStatusCode.MethodNotAllowed, (await client.DeleteAsync("/v1/auth/otp/request")).StatusCode);
        Assert.Equal("nosniff", missing.Headers.GetValues("X-Content-Type-Options").Single());
    }

    [Fact]
    public async Task Bodies_are_validated_against_the_spec_before_the_action()
    {
        var customer = Hosts.Token(app.Services, ["customer"]);
        var invalid = await client.SendAsync(Hosts.Request(HttpMethod.Post, $"/v1/customer/bookings/{Guid.NewGuid()}/review", customer, new { }));
        Assert.Equal(HttpStatusCode.UnprocessableEntity, invalid.StatusCode);
        var reason = JsonDocument.Parse(await invalid.Content.ReadAsStringAsync()).RootElement.GetProperty("error").GetProperty("details").GetProperty("reason").GetString();
        Assert.Equal("body must have required property 'stars'", reason);
        var valid = await client.SendAsync(Hosts.Request(HttpMethod.Get, $"/v1/customer/providers/{Guid.NewGuid()}/reviews", customer));
        Assert.Equal(HttpStatusCode.OK, valid.StatusCode);
    }

    [Fact]
    public async Task Protected_operations_need_a_valid_unrevoked_token_and_the_permission()
    {
        Assert.Equal("UNAUTHENTICATED", await Hosts.ErrorCode(await client.GetAsync("/v1/admin/audit")));
        Assert.Equal("UNAUTHENTICATED", await Hosts.ErrorCode(await client.SendAsync(Hosts.Request(HttpMethod.Get, "/v1/admin/audit", "garbage"))));
        var customer = Hosts.Token(app.Services, ["customer"]);
        var forbidden = await client.SendAsync(Hosts.Request(HttpMethod.Get, "/v1/admin/audit", customer));
        Assert.Equal(HttpStatusCode.Forbidden, forbidden.StatusCode);
        Assert.Contains("audit:read", await forbidden.Content.ReadAsStringAsync(), StringComparison.Ordinal);
        var admin = Hosts.Token(app.Services, ["super_admin"]);
        Assert.Equal(HttpStatusCode.OK, (await client.SendAsync(Hosts.Request(HttpMethod.Get, "/v1/admin/audit", admin))).StatusCode);
        Assert.Equal(HttpStatusCode.OK, (await client.SendAsync(Hosts.Request(HttpMethod.Get, $"/v1/customer/providers/{Guid.NewGuid()}/reviews", customer))).StatusCode);
        var claims = app.Services.GetRequiredService<TokenVerifier>().Verify(admin);
        await app.Services.GetRequiredService<Denylist>().Deny(claims.TokenId, TimeSpan.FromMinutes(1));
        Assert.Equal("UNAUTHENTICATED", await Hosts.ErrorCode(await client.SendAsync(Hosts.Request(HttpMethod.Get, "/v1/admin/audit", admin))));
        var ring = app.Services.GetRequiredService<JwtKeyRing>();
        var expired = new TokenSigner(ring.Signing, new FakeClock(DateTimeOffset.UtcNow.AddHours(-1)), new SequenceIds()).Sign(new TokenRequest(Guid.NewGuid().ToString(), ["customer"])).Token;
        Assert.Equal("TOKEN_EXPIRED", await Hosts.ErrorCode(await client.SendAsync(Hosts.Request(HttpMethod.Get, $"/v1/customer/providers/{Guid.NewGuid()}/reviews", expired))));
    }

    [Fact]
    public async Task Idempotent_operations_replay_the_first_answer()
    {
        var token = Hosts.Token(app.Services, ["customer"]);
        var bodies = new Dictionary<string, object>();
        HttpRequestMessage Create(string key, string note)
        {
            if (!bodies.TryGetValue(note, out var payload))
            {
                bodies[note] = payload = Booking(note);
            }
            var request = Hosts.Request(HttpMethod.Post, "/v1/customer/bookings", token, payload);
            request.Headers.Add("Idempotency-Key", key);
            return request;
        }
        var body = Booking("first");
        var first = Hosts.Request(HttpMethod.Post, "/v1/customer/bookings", token, body);
        first.Headers.Add("Idempotency-Key", "key-00001");
        var created = await client.SendAsync(first);
        Assert.Equal(HttpStatusCode.Created, created.StatusCode);
        var again = Hosts.Request(HttpMethod.Post, "/v1/customer/bookings", token, body);
        again.Headers.Add("Idempotency-Key", "key-00001");
        var replay = await client.SendAsync(again);
        Assert.Equal(HttpStatusCode.Created, replay.StatusCode);
        Assert.Equal("true", replay.Headers.GetValues("Idempotent-Replayed").Single());
        Assert.Equal(await created.Content.ReadAsStringAsync(), await replay.Content.ReadAsStringAsync());
        Assert.Equal("IDEMPOTENCY_KEY_REUSED", await Hosts.ErrorCode(await client.SendAsync(Create("key-00001", "other"))));
        Assert.Equal(HttpStatusCode.InternalServerError, (await client.SendAsync(Create("key-00002", "fail"))).StatusCode);
        Assert.Equal(HttpStatusCode.Created, (await client.SendAsync(Create("key-00002", "fail2"))).StatusCode);
        var gone = await client.SendAsync(Create("key-00003", "domain"));
        Assert.Equal(HttpStatusCode.Gone, gone.StatusCode);
        Assert.Equal(HttpStatusCode.Gone, (await client.SendAsync(Create("key-00003", "domain"))).StatusCode);
    }

    [Fact]
    public async Task A_running_request_blocks_its_key()
    {
        var subject = Guid.NewGuid();
        var token = Hosts.Token(app.Services, ["customer"], subject);
        var keys = app.Services.GetRequiredService<RedisKeys>();
        var body = Booking("x");
        var request = Hosts.Request(HttpMethod.Post, "/v1/customer/bookings", token, body);
        request.Headers.Add("Idempotency-Key", "key-running");
        var raw = await request.Content!.ReadAsByteArrayAsync();
        var hash = PAO.Infrastructure.Http.Filters.IdempotencyFilter.RequestHash("POST", "/v1/customer/bookings", raw);
        await app.Services.GetRequiredService<IdempotencyStore>().Reserve(keys.Key("idem", subject.ToString(), "key-running"), hash);
        var conflict = await client.SendAsync(request);
        Assert.Equal(HttpStatusCode.Conflict, conflict.StatusCode);
    }

    [Fact]
    public async Task Anonymous_calls_are_rate_limited_per_ip()
    {
        HttpResponseMessage last = null!;
        for (var i = 0; i < 61; i++)
        {
            last = await client.SendAsync(Hosts.Request(HttpMethod.Post, "/v1/auth/otp/verify", body: new { }));
        }
        Assert.Equal(HttpStatusCode.TooManyRequests, last.StatusCode);
        Assert.True(int.Parse(last.Headers.GetValues("Retry-After").Single(), System.Globalization.CultureInfo.InvariantCulture) >= 1);
    }

    [Fact]
    public async Task Test_hooks_read_codes_the_captured_sms_adapter_kept()
    {
        await app.Services.GetRequiredService<ISmsSender>().Send("+8801712345678", "code 654321", CancellationToken.None);
        Assert.Contains("654321", await client.GetStringAsync("/__test/sms?phone=01712345678"), StringComparison.Ordinal);
    }

    [Fact]
    public async Task Commands_run_in_one_transaction_and_queries_in_none()
    {
        using var scope = app.Services.CreateScope();
        var mediator = scope.ServiceProvider.GetRequiredService<IMediator>();
        await mediator.Send(new InsertPermission("txn:ok-outer", false));
        await Assert.ThrowsAsync<InvalidOperationException>(() => mediator.Send(new InsertPermission("txn:bad", true)));
        using var check = app.Services.CreateScope();
        Assert.Equal(2, await check.ServiceProvider.GetRequiredService<IMediator>().Send(new CountPermissions("txn:")));
    }
}
