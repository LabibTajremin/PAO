using System.Net;
using System.Net.Http.Headers;
using System.Text;
using System.Text.Json;
using Microsoft.Extensions.DependencyInjection;
using PAO.Infrastructure.Outbox;
using PAO.Lib.Areas.Catalog;
using PAO.Lib.Mediator;

namespace PAO.IntegrationTests.Areas;

/// <summary>
/// The scene of the booking, rating and admin tests: a verified electrician online next to a
/// customer with a saved Banani address, every area real.
/// </summary>
public sealed class BookingWorld
{
    public static readonly Guid Electrician = MerchantSteps.Electrician;
    public static readonly Guid Fan = SeedIds.For("sub-service", "fan-install");
    public static readonly Guid Socket = SeedIds.For("sub-service", "socket-install");
    public static readonly Guid Tap = SeedIds.For("sub-service", "tap-repair");

    private BookingWorld(PeopleApi api, (Guid Id, string Token) provider, (Guid Id, string Token) customer, Guid addressId)
    {
        Api = api;
        Provider = provider;
        Customer = customer;
        AddressId = addressId;
    }

    public PeopleApi Api { get; }
    public (Guid Id, string Token) Provider { get; private set; }
    public (Guid Id, string Token) Customer { get; private set; }
    public Guid AddressId { get; }

    public static async Task<BookingWorld> Create(PeopleApi api, string providerPhone = "01712345601", string customerPhone = "01812345602")
    {
        var provider = await VerifiedProvider(api, providerPhone, Electrician);
        var (customer, address) = await NewCustomer(api, customerPhone);
        return new BookingWorld(api, provider, customer, address);
    }

    /// <summary>A Level 1 merchant online near Banani, verified in Verification and Merchant alike.</summary>
    public static async Task<(Guid Id, string Token)> VerifiedProvider(PeopleApi api, string phone, Guid service, string gender = "male")
    {
        var p = await api.Enrol(phone, gender, service);
        // The enrolment events reach Verification first, so the level set here is the last word.
        await Relay(api);
        await api.Sql($"INSERT INTO verification.levels (provider_id, level) VALUES ('{p.Id}', 1) ON CONFLICT (provider_id) DO UPDATE SET level = 1");
        await api.Deliver("verification.ProviderLevelChanged", new { providerId = p.Id, from = 0, to = 1 });
        Assert.Equal(HttpStatusCode.OK, (await api.Call(HttpMethod.Post, "/v1/provider/presence/online", p.Token, MerchantSteps.Near)).Status);
        return p;
    }

    /// <summary>A customer with a profile ("Nusrat Jahan") and a Banani address.</summary>
    public static async Task<((Guid Id, string Token) Customer, Guid AddressId)> NewCustomer(PeopleApi api, string phone)
    {
        var c = await api.SignIn(phone, "customer");
        Assert.Equal(HttpStatusCode.OK, (await api.Call(HttpMethod.Put, "/v1/customer/profile", c.Token, new { name = "Nusrat Jahan", language = "bn" })).Status);
        var address = new { label = "home", line1 = "House 12, Road 5", line2 = "Block C", area = "Banani", location = new { lat = 23.7937, lng = 90.4066 } };
        var added = await api.Call(HttpMethod.Post, "/v1/customer/addresses", c.Token, address);
        Assert.Equal(HttpStatusCode.Created, added.Status);
        return (c, Guid.Parse(added.Body.GetProperty("id").GetString()!));
    }

    public object Body(Dictionary<string, object?>? extra = null)
    {
        var body = new Dictionary<string, object?>
        {
            ["providerId"] = Provider.Id,
            ["serviceId"] = Electrician,
            ["timing"] = "asap",
            ["addressId"] = AddressId,
            ["items"] = new[] { new { subServiceId = Fan, quantity = 2 } },
            ["note"] = "Second floor",
        };
        foreach (var (k, v) in extra ?? [])
        {
            body[k] = v;
        }
        return body;
    }

    /// <summary>Posts a booking request with `key`.</summary>
    public Task<(HttpStatusCode Status, JsonElement Body)> Request(string key, Dictionary<string, object?>? extra = null, string? token = null) =>
        Send(HttpMethod.Post, "/v1/customer/bookings", token ?? Customer.Token, Body(extra), "booking-" + key);

    /// <summary>Books and returns the id.</summary>
    public async Task<Guid> Book(string key, Dictionary<string, object?>? extra = null)
    {
        var r = await Request(key, extra);
        Assert.True(r.Status == HttpStatusCode.Created, r.Body.ToString());
        return Guid.Parse(r.Body.GetProperty("id").GetString()!);
    }

    public Task<(HttpStatusCode Status, JsonElement Body)> Job(Guid id, string action, object? body = null, string? token = null) =>
        Api.Call(HttpMethod.Post, $"/v1/provider/jobs/{id}/{action}", token ?? Provider.Token, body);

    public Task<(HttpStatusCode Status, JsonElement Body)> AsCustomer(HttpMethod method, string path, object? body = null) => Api.Call(method, path, Customer.Token, body);

    public Task<(HttpStatusCode Status, JsonElement Body)> AsProvider(HttpMethod method, string path, object? body = null) => Api.Call(method, path, Provider.Token, body);

    public async Task<string> Code(Guid id) => (await AsCustomer(HttpMethod.Get, $"/v1/customer/bookings/{id}/start-code")).Body.GetProperty("code").GetString()!;

    /// <summary>Accepts, travels, arrives and starts the job.</summary>
    public async Task Run(Guid id)
    {
        Assert.Equal(HttpStatusCode.OK, (await Job(id, "accept")).Status);
        var code = await Code(id);
        await Job(id, "on-the-way");
        await Job(id, "arrived");
        Assert.Equal(HttpStatusCode.OK, (await Job(id, "start", new { code })).Status);
    }

    /// <summary>Books and runs a job to completion.</summary>
    public async Task<Guid> Completed(string key)
    {
        var id = await Book(key);
        await Run(id);
        Assert.Equal(HttpStatusCode.OK, (await Job(id, "complete", new { cashReceived = true })).Status);
        return id;
    }

    /// <summary>Signs both parties in again, after the clock passed their tokens' expiry.</summary>
    public async Task RefreshTokens(string providerPhone = "01712345601", string customerPhone = "01812345602")
    {
        Provider = await Api.SignIn(providerPhone, "partner");
        Customer = await Api.SignIn(customerPhone, "customer");
    }

    /// <summary>Delivers every pending outbox event to every area's subscribers, as the worker would.</summary>
    public Task Relay() => Relay(Api);

    /// <summary>Delivers every pending outbox event of `api` to every area's subscribers.</summary>
    public static async Task Relay(PeopleApi api)
    {
        var relay = new OutboxRelay(
            api.Services.GetRequiredService<Npgsql.NpgsqlDataSource>(), api.Bus(true), OutboxModules, api.Clock,
            api.Services.GetRequiredService<PAO.Infrastructure.Metrics.PaoMetrics>().Worker,
            Microsoft.Extensions.Logging.Abstractions.NullLogger<OutboxRelay>.Instance);
        while (await relay.RunOnce(CancellationToken.None) > 0)
        {
        }
    }

    /// <summary>Runs a request in its own scope.</summary>
    public async Task<T> Send<T>(IRequest<T> request)
    {
        using var scope = Api.Services.CreateScope();
        return await scope.ServiceProvider.GetRequiredService<IMediator>().Send(request);
    }

    /// <summary>Runs a shared contract in its own scope.</summary>
    public async Task<T> Contract<TService, T>(Func<TService, Task<T>> call)
        where TService : notnull
    {
        using var scope = Api.Services.CreateScope();
        return await call(scope.ServiceProvider.GetRequiredService<TService>());
    }

    private static readonly string[] OutboxModules = ["identity", "customer", "provider", "verification", "catalog", "booking", "rating", "media", "admin", "billing"];

    private async Task<(HttpStatusCode Status, JsonElement Body)> Send(HttpMethod method, string path, string token, object body, string key)
    {
        using var request = new HttpRequestMessage(method, path) { Content = new StringContent(JsonSerializer.Serialize(body), Encoding.UTF8, "application/json") };
        request.Headers.Authorization = new AuthenticationHeaderValue("Bearer", token);
        request.Headers.Add("Idempotency-Key", key);
        using var response = await Api.Api.Client.SendAsync(request);
        var text = await response.Content.ReadAsStringAsync();
        return (response.StatusCode, text.Length == 0 ? default : JsonDocument.Parse(text).RootElement.Clone());
    }
}
