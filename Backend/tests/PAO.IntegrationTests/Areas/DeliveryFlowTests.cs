using System.Net;
using System.Text.Json;
using Microsoft.EntityFrameworkCore;
using Microsoft.Extensions.DependencyInjection;
using PAO.BackgroundJobs;
using PAO.EF;
using PAO.Lib.Areas.Catalog;
using PAO.TestKit;

namespace PAO.IntegrationTests.Areas;

/// <summary>
/// The P25 journey (ADR-0041): weekday office lunch for two weeks, one day skipped, the
/// deliveries made into bookings at the cutoff and each paid in cash.
/// </summary>
public sealed class DeliveryFlowTests : IAsyncLifetime
{
    public static readonly Guid Lunch = SeedIds.For("service", "office-lunch");
    public static readonly Guid Box = SeedIds.For("sub-service", "lunch-box");

    private PeopleApi api = null!;
    private string url = string.Empty;

    public async ValueTask InitializeAsync() => api = await PeopleApi.Start(url = await TestDatabases.CreateMigrated());

    public async ValueTask DisposeAsync()
    {
        await api.DisposeAsync();
        await TestDatabases.Drop(url);
    }

    /// <summary>Dhaka time on a December 2026 day.</summary>
    internal static DateTimeOffset Dhaka(int day, int hour, int minute = 0) => new DateTimeOffset(2026, 12, day, hour, minute, 0, TimeSpan.FromHours(6)).ToUniversalTime();

    internal static async Task<BookingWorld> World(PeopleApi api)
    {
        // Thursday the 3rd, 10:00 in Dhaka; the order starts on Sunday the 6th.
        api.Clock.Now = Dhaka(3, 10);
        var provider = await BookingWorld.VerifiedProvider(api, "01712345611", Lunch, "female");
        var (customer, address) = await BookingWorld.NewCustomer(api, "01812345612");
        return BookingWorld.For(api, provider, customer, address);
    }

    internal static Dictionary<string, object?> Order(BookingWorld w, Dictionary<string, object?>? extra = null)
    {
        var body = new Dictionary<string, object?>
        {
            ["providerId"] = w.Provider.Id,
            ["serviceId"] = Lunch,
            ["items"] = new[] { new { subServiceId = Box, quantity = 2 } },
            ["addressId"] = w.AddressId,
            ["pattern"] = "weekdays",
            ["weekdays"] = new[] { 0, 1, 2, 3, 4 },
            ["window"] = new { start = "12:00", end = "13:00" },
            ["startDate"] = "2026-12-06",
            ["endDate"] = "2026-12-17",
            ["note"] = "Reception, 5th floor",
        };
        foreach (var (k, v) in extra ?? [])
        {
            body[k] = v;
        }
        // A null in extra leaves the field out, as the apps do.
        return body.Where(p => p.Value is not null).ToDictionary();
    }

    internal static string? Status((HttpStatusCode, JsonElement Body) r) => r.Body.GetProperty("status").GetString();

    internal static JsonElement Day(JsonElement subscription, string date) =>
        subscription.GetProperty("upcoming").EnumerateArray().Single(d => d.GetProperty("date").GetString() == date);

    internal static async Task<int> Sweep(PeopleApi api)
    {
        var job = new MaterialiseDeliveriesJob(api.Services.GetRequiredService<IServiceScopeFactory>());
        await job.Run(CancellationToken.None);
        using var scope = api.Services.CreateScope();
        return (await scope.ServiceProvider.GetRequiredService<PaoDbContext>().Database
            .SqlQuery<int>($"SELECT count(*)::int AS \"Value\" FROM booking.subscription_dates WHERE state = 'booked'").ToListAsync())[0];
    }

    private static async Task<int> Count(PeopleApi api, string sql)
    {
        using var scope = api.Services.CreateScope();
        return (await scope.ServiceProvider.GetRequiredService<PaoDbContext>().Database.SqlQueryRaw<int>(sql).ToListAsync())[0];
    }

    [Fact]
    public async Task Weekday_lunch_for_two_weeks_skips_a_day_and_each_delivery_is_paid_in_cash()
    {
        var w = await World(api);
        var id = await OrderAndAccept(w);
        await ChangeTwoDates(w, id);
        var booking = await SweepAtTheCutoff(w, id);
        await Deliver(w, id, booking);
        await LaterDays(w, id);
        await PauseResumeAndCancel(w, id);
    }

    private async Task<string> OrderAndAccept(BookingWorld w)
    {
        var ordered = await w.Send(HttpMethod.Post, "/v1/customer/subscriptions", w.Customer.Token, Order(w), "subscription-1");
        Assert.True(ordered.Status == HttpStatusCode.Created, ordered.Body.ToString());
        var id = ordered.Body.GetProperty("id").GetString()!;
        Assert.Equal(("requested", 10, 36000L), (Status(ordered), ordered.Body.GetProperty("upcoming").GetArrayLength(), ordered.Body.GetProperty("total").GetInt64()));
        Assert.False(ordered.Body.GetProperty("provider").TryGetProperty("phone", out _));
        var repeat = await w.Send(HttpMethod.Post, "/v1/customer/subscriptions", w.Customer.Token, Order(w), "subscription-1");
        Assert.Equal(id, repeat.Body.GetProperty("id").GetString());
        var inbox = await w.AsProvider(HttpMethod.Get, "/v1/provider/subscriptions?status=requested");
        Assert.Equal("Banani", inbox.Body.GetProperty("items")[0].GetProperty("address").GetProperty("area").GetString());
        Assert.Equal("active", Status(await w.AsProvider(HttpMethod.Post, $"/v1/provider/subscriptions/{id}/accept")));
        Assert.Equal("BOOKING_INVALID_TRANSITION", PeopleApi.Code((await w.AsProvider(HttpMethod.Post, $"/v1/provider/subscriptions/{id}/accept")).Body));
        return id;
    }

    private static async Task ChangeTwoDates(BookingWorld w, string id)
    {
        var skipped = await w.AsCustomer(HttpMethod.Put, $"/v1/customer/subscriptions/{id}/deliveries/2026-12-07", new { skip = true });
        Assert.Equal("skipped", Status(skipped));
        var more = await w.AsCustomer(HttpMethod.Put, $"/v1/customer/subscriptions/{id}/deliveries/2026-12-08", new { items = new[] { new { subServiceId = Box, quantity = 3 } } });
        Assert.Equal(54000, more.Body.GetProperty("total").GetInt64());
    }

    /// <summary>Saturday 20:01: Sunday's cutoff has passed, so the sweep books it and it can no longer change.</summary>
    private async Task<Guid> SweepAtTheCutoff(BookingWorld w, string id)
    {
        api.Clock.Now = Dhaka(5, 20, 1);
        await w.RefreshTokens("01712345611", "01812345612");
        Assert.Equal("DELIVERY_CUTOFF_PASSED", PeopleApi.Code((await w.AsCustomer(HttpMethod.Put, $"/v1/customer/subscriptions/{id}/deliveries/2026-12-06", new { skip = true })).Body));
        Assert.Equal(1, await Sweep(api));
        Assert.Equal(1, await Sweep(api));
        var sunday = Day((await w.AsCustomer(HttpMethod.Get, $"/v1/customer/subscriptions/{id}")).Body, "2026-12-06");
        Assert.Equal(("scheduled", false), (sunday.GetProperty("status").GetString(), sunday.GetProperty("changeable").GetBoolean()));
        var calendar = await w.AsProvider(HttpMethod.Get, "/v1/provider/deliveries?from=2026-12-05&to=2026-12-18");
        Assert.Equal(9, calendar.Body.GetProperty("items").GetArrayLength());
        return Guid.Parse(sunday.GetProperty("bookingId").GetString()!);
    }

    private async Task<string?> SundayStatus(BookingWorld w, string id) =>
        Day((await w.AsCustomer(HttpMethod.Get, $"/v1/customer/subscriptions/{id}")).Body, "2026-12-06").GetProperty("status").GetString();

    /// <summary>Sunday at noon the merchant delivers, takes the cash and the commission is charged.</summary>
    private async Task Deliver(BookingWorld w, string id, Guid booking)
    {
        api.Clock.Now = Dhaka(6, 12, 5);
        await w.RefreshTokens("01712345611", "01812345612");
        Assert.Equal("preparing", await SundayStatus(w, id));
        var code = await w.Code(booking);
        await w.Job(booking, "on-the-way");
        Assert.Equal("out_for_delivery", await SundayStatus(w, id));
        await w.Job(booking, "arrived");
        Assert.Equal(HttpStatusCode.OK, (await w.Job(booking, "start", new { code })).Status);
        Assert.Equal("completed", Status(await w.Job(booking, "complete", new { cashReceived = true })));
        await w.Relay();
        Assert.Equal("delivered", await SundayStatus(w, id));
        Assert.Equal(1, await Count(api, $"SELECT count(*)::int AS \"Value\" FROM billing.ledger_entries WHERE booking_id = '{booking}'"));
        Assert.Equal(2, await Count(api, "SELECT count(*)::int AS \"Value\" FROM notification.notifications WHERE type IN ('delivery_tomorrow', 'deliveries_tomorrow')"));
        Assert.Equal(1, await Count(api, "SELECT count(*)::int AS \"Value\" FROM notification.notifications WHERE type = 'subscription_accepted'"));
    }

    /// <summary>Monday is skipped: nothing to book. Monday 20:01 books Tuesday with its three boxes.</summary>
    private async Task LaterDays(BookingWorld w, string id)
    {
        api.Clock.Now = Dhaka(6, 20, 1);
        Assert.Equal(1, await Sweep(api));
        api.Clock.Now = Dhaka(7, 20, 1);
        await w.RefreshTokens("01712345611", "01812345612");
        Assert.Equal("declined", Status(await w.AsProvider(HttpMethod.Post, $"/v1/provider/subscriptions/{id}/deliveries/2026-12-09/decline")));
        Assert.Equal(2, await Sweep(api));
        var tuesday = Day((await w.AsCustomer(HttpMethod.Get, $"/v1/customer/subscriptions/{id}")).Body, "2026-12-08");
        var receipt = await w.AsCustomer(HttpMethod.Get, $"/v1/customer/bookings/{tuesday.GetProperty("bookingId").GetString()}");
        Assert.Equal((54000L, "cash_on_delivery"), (receipt.Body.GetProperty("total").GetInt64(), receipt.Body.GetProperty("paymentMethod").GetString()));
        Assert.Equal("BOOKING_INVALID_TRANSITION",
            PeopleApi.Code((await w.AsCustomer(HttpMethod.Put, $"/v1/customer/subscriptions/{id}/deliveries/2026-12-09", new { skip = false })).Body));
    }

    private async Task PauseResumeAndCancel(BookingWorld w, string id)
    {
        Assert.Equal("paused", Status(await w.AsCustomer(HttpMethod.Post, $"/v1/customer/subscriptions/{id}/pause")));
        Assert.Equal("skipped", Day((await w.AsProvider(HttpMethod.Get, $"/v1/provider/subscriptions/{id}")).Body, "2026-12-10").GetProperty("status").GetString());
        Assert.Equal("active", Status(await w.AsCustomer(HttpMethod.Post, $"/v1/customer/subscriptions/{id}/resume")));
        Assert.Equal("cancelled", Status(await w.AsCustomer(HttpMethod.Post, $"/v1/customer/subscriptions/{id}/cancel")));
        Assert.Equal("BOOKING_INVALID_TRANSITION", PeopleApi.Code((await w.AsCustomer(HttpMethod.Post, $"/v1/customer/subscriptions/{id}/resume")).Body));
        await w.Relay();
        Assert.Equal(1, await Count(api, "SELECT count(*)::int AS \"Value\" FROM notification.notifications WHERE type = 'delivery_declined'"));
        Assert.Equal(3, await Count(api, "SELECT count(*)::int AS \"Value\" FROM notification.notifications WHERE type = 'subscription_changed'"));
    }
}
