using System.Net;
using Microsoft.EntityFrameworkCore;
using Microsoft.Extensions.DependencyInjection;
using PAO.BackgroundJobs;
using PAO.EF;
using PAO.Infrastructure.Redis;
using PAO.Lib.Areas.Merchant;
using PAO.Lib.Common;
using StackExchange.Redis;
using static PAO.IntegrationTests.Areas.MerchantSteps;

namespace PAO.IntegrationTests.Areas;

public sealed class MerchantPresenceTests(MigratedDatabase database) : IClassFixture<MigratedDatabase>, IAsyncLifetime
{
    private const string Beat = "/v1/provider/presence/heartbeat";
    private static readonly GeoPoint Dhaka = new() { Lat = 23.7937, Lng = 90.4066 };
    private PeopleApi api = null!;

    public async ValueTask InitializeAsync() => api = await PeopleApi.Start(database.Url);

    public async ValueTask DisposeAsync() => await api.DisposeAsync();

    private Task<bool> Available(Guid id) => api.Merchants(m => m.IsAvailable(id, CancellationToken.None));

    private async Task<T> Db<T>(Func<PaoDbContext, Task<T>> work)
    {
        using var scope = api.Services.CreateScope();
        return await work(scope.ServiceProvider.GetRequiredService<PaoDbContext>());
    }

    [Fact]
    public async Task Goes_online_beats_goes_offline_and_is_reaped()
    {
        var unverified = await api.Enrol("01912345678", "male", Electrician);
        Assert.Equal("NOT_VERIFIED", PeopleApi.Code((await api.Call(HttpMethod.Post, "/v1/provider/presence/online", unverified.Token, Near)).Body));
        var (id, token) = await api.Online("01712345678", "male", 1, Electrician);
        var beat = await api.Call(HttpMethod.Post, Beat, token, Near);
        Assert.Equal((HttpStatusCode.OK, 30), (beat.Status, beat.Body.GetProperty("heartbeatIntervalSeconds").GetInt32()));
        var profile = await api.Call(HttpMethod.Get, "/v1/provider/profile", token);
        Assert.True(profile.Body.GetProperty("online").GetBoolean());
        Assert.Equal("verified", profile.Body.GetProperty("badge").GetString());
        Assert.True(await Available(id));
        Assert.False((await api.Call(HttpMethod.Post, "/v1/provider/presence/offline", token)).Body.GetProperty("online").GetBoolean());
        Assert.Equal("OFFLINE", PeopleApi.Code((await api.Call(HttpMethod.Post, Beat, token, Near)).Body));
        await api.Call(HttpMethod.Post, "/v1/provider/presence/online", token, Near);
        var keys = api.Services.GetRequiredService<RedisKeys>();
        var redis = api.Services.GetRequiredService<IConnectionMultiplexer>().GetDatabase();
        await redis.KeyDeleteAsync(keys.Key("presence", "hb", id.ToString()));
        var stray = Guid.NewGuid();
        await redis.SetAddAsync(keys.Key("presence", "online"), stray.ToString());
        await new MerchantPresenceReapJob(api.Services.GetRequiredService<IServiceScopeFactory>()).Run(CancellationToken.None);
        Assert.False(await Available(id));
        Assert.False(await redis.SetContainsAsync(keys.Key("presence", "online"), stray.ToString()));
        await api.Call(HttpMethod.Post, "/v1/provider/presence/online", token, Near);
        await api.Merchants(async m => { await m.ForceOffline(id, CancellationToken.None); return 0; });
        Assert.Equal("OFFLINE", PeopleApi.Code((await api.Call(HttpMethod.Post, Beat, token, Near)).Body));
        await api.Call(HttpMethod.Post, "/v1/provider/presence/online", token, Near);
        await api.Call(HttpMethod.Put, "/v1/provider/enrolment/services", token, new { serviceIds = new[] { Electrician }, experienceYears = 9 });
        Assert.False(await Available(id));
        var stranger = api.Api.Token("provider");
        foreach (var path in new[] { "/v1/provider/presence/online", Beat })
        {
            Assert.Equal(HttpStatusCode.NotFound, (await api.Call(HttpMethod.Post, path, stranger, Near)).Status);
        }
        Assert.Equal(HttpStatusCode.NotFound, (await api.Call(HttpMethod.Post, "/v1/provider/presence/offline", stranger)).Status);
    }

    [Fact]
    public async Task Needs_services_and_an_area_to_go_online()
    {
        var (_, noArea) = await api.SignIn("01712345699", "partner");
        await api.Call(HttpMethod.Put, "/v1/provider/enrolment/personal", noArea, Personal("male"));
        var noAreaId = (await api.Call(HttpMethod.Get, "/v1/provider/profile", noArea)).Body.GetProperty("id").GetGuid();
        await api.Deliver("verification.ProviderLevelChanged", new { providerId = noAreaId, to = 1 });
        Assert.Equal("SERVICE_AREA_MISSING", PeopleApi.Code((await api.Call(HttpMethod.Post, "/v1/provider/presence/online", noArea, Near)).Body));
    }

    [Fact]
    public async Task Ranks_and_honours_women_only_services()
    {
        var man = await api.Online("01712345601", "male", 1, Electrician, HomeSalon);
        var woman = await api.Online("01712345602", "female", 1, HomeSalon);
        var pro = await api.Online("01712345603", "female", 2, Electrician, HomeSalon);
        var q = new NearbyQuery { ServiceId = HomeSalon, Point = Dhaka, RadiusM = 5000, WomenProvidersOnly = false, Sort = SortOrder.Distance, Limit = 10 };
        var salon = await api.Merchants(m => m.FindNearby(q, CancellationToken.None));
        Assert.Equal([pro.Id, woman.Id], salon.Select(c => c.ProviderId));
        Assert.Equal("Rahim Uddin", salon[0].Name);
        var elec = await api.Merchants(m => m.FindNearby(q with { ServiceId = Electrician, Sort = SortOrder.Rating, Limit = 0 }, CancellationToken.None));
        Assert.Equal([pro.Id, man.Id], elec.Select(c => c.ProviderId));
        Assert.Single(await api.Merchants(m => m.FindNearby(q with { ServiceId = Electrician, Limit = 1 }, CancellationToken.None)));
        Assert.Equal([pro.Id], (await api.Merchants(m => m.FindNearby(q with { ServiceId = Electrician, WomenProvidersOnly = true }, CancellationToken.None))).Select(c => c.ProviderId));
        await Db(db => db.Database.ExecuteSqlAsync($"UPDATE catalog.services SET requires_level_2 = true WHERE id = {HomeSalon}"));
        Assert.Equal([pro.Id], (await api.Merchants(m => m.FindNearby(q, CancellationToken.None))).Select(c => c.ProviderId));
        Assert.Empty(await api.Merchants(m => m.FindNearby(q with { Point = new GeoPoint { Lat = 22.35, Lng = 91.78 }, ServiceId = Electrician }, CancellationToken.None)));
        await Assert.ThrowsAnyAsync<Exception>(() => api.Merchants(m => m.FindNearby(q with { ServiceId = Guid.NewGuid() }, CancellationToken.None)));
        var online = await api.Merchants(m => m.SearchMerchants(new MerchantQuery { Id = pro.Id, Text = string.Empty, Status = string.Empty, Limit = 5 }, CancellationToken.None));
        Assert.True(Assert.Single(online).Online);
        var (_, customer) = await api.SignIn("01812345601", "customer");
        await api.Sql($"INSERT INTO rating.aggregates (subject_id, subject_role, review_count, star_sum, stars_4, stars_5) VALUES ('{pro.Id}', 'provider', 2, 9, 1, 1)");
        var shown = await api.Call(HttpMethod.Get, $"/v1/customer/providers/{pro.Id}", customer);
        Assert.Equal((HttpStatusCode.OK, "verified_pro", 1), (shown.Status, shown.Body.GetProperty("badge").GetString(), shown.Body.GetProperty("rating").GetProperty("distribution").GetProperty("5").GetInt32()));
        var unverified = await api.Enrol("01712345604", "male", Electrician);
        Assert.Equal(HttpStatusCode.NotFound, (await api.Call(HttpMethod.Get, $"/v1/customer/providers/{unverified.Id}", customer)).Status);
    }

    [Fact]
    public async Task Flags_merchants_and_keeps_the_read_model()
    {
        var rated = await api.Online("01712345611", "male", 1, Electrician);
        var review = (Guid id, string role, double avg, int n) => new { subjectId = id, subjectRole = role, newAverage = avg, newCount = n };
        await api.Deliver("rating.ReviewSubmitted", review(rated.Id, "customer", 1, 50));
        await api.Deliver("rating.ReviewSubmitted", review(rated.Id, "provider", 3, 9));
        Assert.Equal((false, ""), await Flag(rated.Id));
        await api.Deliver("booking.BookingCompleted", new { bookingId = Guid.NewGuid(), providerId = rated.Id });
        await api.Deliver("rating.ReviewSubmitted", review(rated.Id, "provider", 3, 10));
        Assert.Equal((true, "rating_below_floor"), await Flag(rated.Id));
        var canceller = await api.Online("01712345612", "male", 1, Electrician);
        var cancelled = (string by) => new { bookingId = Guid.NewGuid(), providerId = canceller.Id, by, afterAcceptance = true };
        await api.Deliver("booking.BookingCancelled", cancelled("customer"));
        for (var i = 0; i < 4; i++)
        {
            await api.Deliver("booking.BookingCancelled", cancelled("provider"));
        }
        Assert.Equal((true, "cancellations"), await Flag(canceller.Id));
        var complained = await api.Online("01712345613", "male", 1, Electrician);
        await api.Deliver("admin.ComplaintResolved", new { againstId = complained.Id, verified = false });
        await api.Deliver("admin.ComplaintResolved", new { againstId = complained.Id, verified = true });
        Assert.Equal((true, "verified_complaint"), await Flag(complained.Id));
        await api.Deliver("identity.AccountStatusChanged", new { accountId = complained.Id, from = "active", to = "suspended", roles = new[] { "provider" } });
        Assert.False(await Available(complained.Id));
        var profile = await api.Call(HttpMethod.Get, "/v1/provider/profile", complained.Token);
        Assert.Equal(("suspended", true), (profile.Body.GetProperty("status").GetString(), profile.Body.GetProperty("flaggedForReview").GetBoolean()));
        await api.Deliver("identity.AccountStatusChanged", new { accountId = complained.Id, from = "suspended", to = "active", roles = new[] { "provider" } });
        await api.Deliver("identity.AccountDeleted", new { accountId = rated.Id });
        await api.Deliver("identity.AccountDeleted", new { accountId = Guid.NewGuid() });
        await Assert.ThrowsAnyAsync<Exception>(() => api.Merchants(m => m.GetMerchant(rated.Id, CancellationToken.None)));
        Assert.Equal(3, await Db(db => db.Database.SqlQuery<int>($"SELECT count(*)::int AS \"Value\" FROM provider.outbox WHERE event_name = 'provider.ProviderFlaggedForReview'").SingleAsync()));
        await api.Deliver("verification.ProviderLevelChanged", new { providerId = canceller.Id, to = 0 });
        Assert.False(await Available(canceller.Id));
    }

    [Fact]
    public async Task Fails_on_broken_payloads_and_lost_settings()
    {
        var bus = api.Bus();
        foreach (var name in new[] { "verification.ProviderLevelChanged", "rating.ReviewSubmitted", "booking.BookingCancelled", "admin.ComplaintResolved", "booking.BookingCompleted" })
        {
            await Assert.ThrowsAnyAsync<Exception>(() => bus.Dispatch(api.Envelope(name, "not json"), CancellationToken.None));
        }
        var p = await api.Online("01712345621", "male", 1, Electrician);
        await api.SettingsDown(true);
        await Assert.ThrowsAnyAsync<Exception>(() => api.Deliver("rating.ReviewSubmitted", new { subjectId = p.Id, subjectRole = "provider", newAverage = 2, newCount = 20 }, bus));
        await Assert.ThrowsAnyAsync<Exception>(() => api.Deliver("booking.BookingCancelled", new { bookingId = Guid.NewGuid(), providerId = p.Id, by = "provider", afterAcceptance = true }, bus));
        await api.SettingsDown(false);
        await api.Deliver("booking.BookingCancelled", new { bookingId = Guid.NewGuid(), providerId = p.Id, by = "provider", afterAcceptance = false }, bus);
    }

    [Fact]
    public async Task The_perf_seed_puts_a_verified_electrician_online()
    {
        var id = Guid.NewGuid();
        using (var scope = api.Services.CreateScope())
        {
            await scope.ServiceProvider.GetRequiredService<PAO.Lib.Mediator.IMediator>().Send(new PAO.Core.Areas.Merchant.Features.PerfSeed.Commands.AddPerfMerchant(id, Dhaka));
        }
        var q = new NearbyQuery { ServiceId = Electrician, Point = Dhaka, RadiusM = 5000, WomenProvidersOnly = false, Sort = SortOrder.Distance, Limit = 0 };
        Assert.Contains(await api.Merchants(m => m.FindNearby(q, CancellationToken.None)), c => c.ProviderId == id);
    }

    private Task<(bool, string)> Flag(Guid id) => Db(async db =>
    {
        var row = await db.Set<PAO.EF.Merchant.MerchantProfileRecord>().SingleAsync(m => m.Id == id);
        return (row.FlaggedForReview, row.FlagReason);
    });
}
