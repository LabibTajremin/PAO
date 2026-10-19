using System.Net;
using System.Text.Json;
using Microsoft.Extensions.DependencyInjection;
using Microsoft.Extensions.DependencyInjection.Extensions;
using PAO.Core.Areas.Admin.Services.Shared;
using PAO.Core.Areas.Customer.Services;
using PAO.Core.Areas.Merchant.Services;
using PAO.Core.Areas.Rating.Services.Shared;
using PAO.Infrastructure.Data;
using PAO.Infrastructure.Events;
using PAO.Infrastructure.Testing;
using PAO.Lib.Areas.Admin;
using PAO.Lib.Areas.Identity;
using PAO.Lib.Areas.Rating;
using PAO.Migrator;
using PAO.TestKit;

namespace PAO.IntegrationTests.Areas;

/// <summary>Stands in for Admin, which is not ported yet: settings the test can change, or a failure.</summary>
public sealed class FakeAdmin : IAdminSharedService
{
    public PlatformSettings Settings { get; set; } = new()
    {
        AcceptTimeoutAsapMs = 0,
        AcceptTimeoutScheduledMs = 0,
        DefaultSearchRadiusM = 5000,
        RatingFloor = 3.5,
        RatingMinJobs = 10,
        MaxProviderCancellations30d = 3,
        StartCodeMaxAttempts = 3,
        StartCodeLockoutMs = 0,
        PoliceClearanceValidityMs = 0,
        Level2CoolingOffMs = 0,
        DocumentRetentionMs = 0,
        ServiceAreaGeoJson = string.Empty,
    };

    public bool Down { get; set; }

    public Task<PlatformSettings> GetSettings(CancellationToken cancellationToken) =>
        Down ? throw new InvalidOperationException("admin down") : Task.FromResult(Settings);

    public Task<int> CountVerifiedComplaints(Guid againstId, CancellationToken cancellationToken) => Task.FromResult(0);
}

/// <summary>Stands in for Rating, which is not ported yet.</summary>
public sealed class FakeRatings : IRatingSharedService
{
    public Task<RatingSummary> GetMerchantRating(Guid merchantId, CancellationToken cancellationToken) =>
        Task.FromResult(new RatingSummary { Average = 4.5, Count = 2, Distribution = [0, 0, 0, 1, 1] });

    public Task<IReadOnlyDictionary<Guid, RatingSummary>> GetMerchantRatings(IReadOnlyCollection<Guid> merchantIds, CancellationToken cancellationToken) =>
        throw new NotSupportedException();

    public Task<RatingSummary> GetCustomerRating(Guid customerId, CancellationToken cancellationToken) => throw new NotSupportedException();

    public Task<bool> HasReviewed(Guid bookingId, Guid authorId, CancellationToken cancellationToken) => throw new NotSupportedException();
}

/// <summary>An API with real Identity, Media and Catalog, seeded, for the Customer and Merchant tests.</summary>
public sealed class PeopleApi : IAsyncDisposable
{
    private static readonly byte[] Jpeg = [.. Enumerable.Repeat((byte)0xff, 1024)];

    private PeopleApi(AreaApi api, FakeClock clock)
    {
        Api = api;
        Clock = clock;
    }

    public AreaApi Api { get; }
    public FakeClock Clock { get; }
    public FakeAdmin Admin => Api.Services.GetRequiredService<FakeAdmin>();
    public IServiceProvider Services => Api.Services;

    public static async Task<PeopleApi> Start(string databaseUrl, bool seed = true)
    {
        if (seed)
        {
            Assert.Equal(0, await SeedCommand.Run(Hosts.Paths, Hosts.Environment(databaseUrl), new StringWriter()));
        }
        var clock = new FakeClock(DateTimeOffset.UtcNow);
        var api = await AreaApi.Start(databaseUrl, services =>
        {
            services.Replace(ServiceDescriptor.Singleton<IClock>(clock));
            services.AddSingleton<FakeAdmin>();
            services.AddSingleton<IAdminSharedService>(sp => sp.GetRequiredService<FakeAdmin>());
            services.AddSingleton<IRatingSharedService, FakeRatings>();
        });
        return new PeopleApi(api, clock);
    }

    public ValueTask DisposeAsync() => Api.DisposeAsync();

    public Task<(HttpStatusCode Status, JsonElement Body)> Call(HttpMethod method, string path, string? token, object? body = null) =>
        Api.Call(method, path, token, body);

    public static string? Code(JsonElement body) =>
        body.ValueKind == JsonValueKind.Object && body.TryGetProperty("error", out var e) ? e.GetProperty("code").GetString() : null;

    public string LastCode(string phone) =>
        Services.GetRequiredService<ISmsCapture>().Last(PhoneNumber.Normalize(phone)!)!.Split("code: ")[1][..6];

    /// <summary>Signs in by phone in the customer or partner app; returns the account id and access token.</summary>
    public async Task<(Guid Id, string Token)> SignIn(string phone, string app)
    {
        Clock.Advance(TimeSpan.FromMinutes(2));
        var sent = await Call(HttpMethod.Post, "/v1/auth/otp/request", null, new { phone });
        Assert.Equal(HttpStatusCode.Accepted, sent.Status);
        var verified = await Call(HttpMethod.Post, "/v1/auth/otp/verify", null, new { phone, code = LastCode(phone), app });
        Assert.Equal(HttpStatusCode.OK, verified.Status);
        var id = Guid.Parse(verified.Body.GetProperty("account").GetProperty("id").GetString()!);
        return (id, verified.Body.GetProperty("accessToken").GetString()!);
    }

    /// <summary>Uploads and confirms a JPEG avatar from the app (`customer` or `provider`); returns its media id.</summary>
    public async Task<Guid> Avatar(string token, string app, string purpose = "avatar")
    {
        var ticket = await Call(HttpMethod.Post, $"/v1/{app}/uploads", token, new { purpose, contentType = "image/jpeg", sizeBytes = Jpeg.Length });
        Assert.Equal(HttpStatusCode.Created, ticket.Status);
        using (var http = new HttpClient())
        using (var content = new ByteArrayContent(Jpeg))
        {
            foreach (var h in ticket.Body.GetProperty("headers").EnumerateObject())
            {
                content.Headers.TryAddWithoutValidation(h.Name, h.Value.GetString());
            }
            Assert.Equal(HttpStatusCode.OK, (await http.PutAsync(ticket.Body.GetProperty("uploadUrl").GetString(), content)).StatusCode);
        }
        var id = ticket.Body.GetProperty("mediaId").GetString()!;
        Assert.Equal(HttpStatusCode.OK, (await Call(HttpMethod.Post, $"/v1/{app}/uploads/{id}/confirm", token)).Status);
        return Guid.Parse(id);
    }

    /// <summary>The bus with every area's subscribers, as the worker builds it.</summary>
    public EventBus Bus()
    {
        var bus = new EventBus();
        foreach (var s in Services.GetServices<IEventSubscriptions>().Where(s => s is CustomerSubscriptions or MerchantSubscriptions))
        {
            s.Subscribe(bus);
        }
        return bus;
    }

    /// <summary>Delivers an event with `payload` to every subscriber.</summary>
    public Task Deliver(string name, object payload, EventBus? bus = null) => (bus ?? Bus()).Dispatch(Envelope(name, payload), CancellationToken.None);

    public Envelope Envelope(string name, object payload) => new()
    {
        Id = Guid.NewGuid(),
        Module = "test",
        Name = name,
        AggregateId = string.Empty,
        Payload = JsonSerializer.SerializeToElement(payload, JsonSerializerOptions.Web),
        OccurredAt = Clock.Now,
    };
}
