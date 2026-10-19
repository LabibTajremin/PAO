using System.Net;
using System.Text.Json;
using Microsoft.Extensions.DependencyInjection;
using Microsoft.Extensions.DependencyInjection.Extensions;
using Microsoft.EntityFrameworkCore;
using PAO.Core.Areas.Admin.Features.Settings.Commands;
using PAO.EF;
using PAO.Infrastructure.Redis;
using PAO.Lib.Mediator;
using PAO.Core.Areas.Customer.Services;
using PAO.Core.Areas.Merchant.Services;
using PAO.Infrastructure.Data;
using PAO.Infrastructure.Events;
using PAO.Infrastructure.Storage;
using PAO.Infrastructure.Testing;
using PAO.Lib.Areas.Identity;
using PAO.Migrator;
using PAO.TestKit;

namespace PAO.IntegrationTests.Areas;

/// <summary>An API with every area real, the catalog seeded, for the Customer, Merchant, Booking, Rating and Admin tests.</summary>
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
    public IServiceProvider Services => Api.Services;

    public static async Task<PeopleApi> Start(string databaseUrl, bool seed = true)
    {
        if (seed)
        {
            Assert.Equal(0, await SeedCommand.Run(Hosts.Paths, Hosts.Environment(databaseUrl), new StringWriter()));
        }
        // A fresh object store (as in CI) has no buckets until a host starts, so the uploads need them here.
        var storage = TestSettings.Create().Storage;
        using (var store = new ObjectStore(storage))
        {
            await store.EnsureBucket(storage.BucketPrivate, CancellationToken.None);
            await store.EnsureBucket(storage.BucketPublic, CancellationToken.None);
        }
        var clock = new FakeClock(DateTimeOffset.UtcNow);
        var api = await AreaApi.Start(databaseUrl, services =>
        {
            services.Replace(ServiceDescriptor.Singleton<IClock>(clock));
        });
        return new PeopleApi(api, clock);
    }

    public ValueTask DisposeAsync() => Api.DisposeAsync();

    /// <summary>Changes a platform setting through Admin's own use case, as a super admin would.</summary>
    public async Task SetSetting(string key, string value)
    {
        using var scope = Services.CreateScope();
        await scope.ServiceProvider.GetRequiredService<IMediator>().Send(new UpdateSetting(Guid.NewGuid(), key, value));
    }

    /// <summary>Takes the settings table away (`down`) or brings it back, emptying the settings cache either way.</summary>
    public async Task SettingsDown(bool down)
    {
        using var scope = Services.CreateScope();
        var db = scope.ServiceProvider.GetRequiredService<PaoDbContext>();
        await db.Database.ExecuteSqlRawAsync(down ? "ALTER TABLE admin.settings RENAME TO settings_gone" : "ALTER TABLE admin.settings_gone RENAME TO settings");
        await ForgetSettings();
    }

    /// <summary>Empties the settings cache, so the next read comes from the database.</summary>
    public Task ForgetSettings() => Services.GetRequiredService<JsonCache>().Delete(Services.GetRequiredService<RedisKeys>().Key("cache", "settings"));

    /// <summary>Runs SQL on the test database.</summary>
    public async Task Sql(string sql)
    {
        using var scope = Services.CreateScope();
        await scope.ServiceProvider.GetRequiredService<PaoDbContext>().Database.ExecuteSqlRawAsync(sql);
    }

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

    /// <summary>The bus with Customer's and Merchant's subscribers, or with every area's (`all`) as the worker builds it.</summary>
    public EventBus Bus(bool all = false)
    {
        var bus = new EventBus();
        foreach (var s in Services.GetServices<IEventSubscriptions>().Where(s => all || s is CustomerSubscriptions or MerchantSubscriptions))
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
