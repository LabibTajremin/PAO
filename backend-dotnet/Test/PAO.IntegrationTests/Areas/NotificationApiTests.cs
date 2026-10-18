using System.Net;
using System.Text.Json;
using Microsoft.EntityFrameworkCore;
using Microsoft.Extensions.DependencyInjection;
using PAO.Core.Areas.Booking.Services.Shared;
using PAO.Core.Areas.Customer.Services.Shared;
using PAO.Core.Areas.Merchant.Services.Shared;
using PAO.Core.Areas.Notification.Services.Shared;
using PAO.EF;
using PAO.Infrastructure.Events;
using PAO.Infrastructure.Testing;
using PAO.Lib.Areas.Notification;
using PAO.Lib.Errors;

namespace PAO.IntegrationTests.Areas;

public sealed class NotificationApiTests(MigratedDatabase database) : IClassFixture<MigratedDatabase>, IAsyncLifetime
{
    private readonly NotificationWorld world = new();
    private AreaApi api = null!;
    private EventBus bus = null!;
    private string customer = string.Empty;
    private string provider = string.Empty;

    public async ValueTask InitializeAsync()
    {
        api = await AreaApi.Start(database.Url, services =>
        {
            services.AddSingleton<ICustomerSharedService>(new FakeCustomers(world));
            services.AddSingleton<IMerchantSharedService>(new FakeMerchants(world));
            services.AddSingleton<IBookingSharedService>(new FakeBookings(world));
        });
        bus = new EventBus();
        foreach (var subscriptions in api.Services.GetServices<IEventSubscriptions>())
        {
            subscriptions.Subscribe(bus);
        }
        customer = api.Token(world.Customer, "customer");
        provider = api.Token(world.Provider, "provider");
    }

    public async ValueTask DisposeAsync() => await api.DisposeAsync();

    private Task Deliver(string name, object payload) => bus.Dispatch(new Envelope
    {
        Id = Guid.NewGuid(),
        Module = "x",
        Name = name,
        AggregateId = string.Empty,
        Payload = JsonSerializer.SerializeToElement(payload),
        OccurredAt = DateTimeOffset.UtcNow,
    }, CancellationToken.None);

    private Dictionary<string, object?> Parties(object? extra = null)
    {
        var parties = new Dictionary<string, object?> { ["bookingId"] = world.Booking, ["customerId"] = world.Customer, ["providerId"] = world.Provider };
        foreach (var p in extra?.GetType().GetProperties() ?? [])
        {
            parties[p.Name] = p.GetValue(extra);
        }
        return parties;
    }

    private async Task<JsonElement> Inbox(string side, string token, string query = "")
    {
        var r = await api.Call(HttpMethod.Get, $"/v1/{side}/notifications{query}", token);
        Assert.Equal(HttpStatusCode.OK, r.Status);
        return r.Body;
    }

    private static List<string> Types(JsonElement page) => [.. page.GetProperty("items").EnumerateArray().Select(i => i.GetProperty("type").GetString()!)];

    [Fact]
    public async Task Every_booking_event_reaches_the_right_inbox()
    {
        var cases = new (string Name, object? Extra, string ToCustomer, string ToProvider)[]
        {
            ("BookingRequested", null, "", "booking_requested"),
            ("BookingAccepted", null, "booking_accepted", ""),
            ("BookingRejected", null, "booking_rejected", ""),
            ("BookingTimedOut", null, "booking_timed_out", "request_missed"),
            ("ProviderOnTheWay", null, "provider_on_the_way", ""),
            ("ProviderArrived", null, "provider_arrived", ""),
            ("BookingStarted", null, "booking_started", ""),
            ("ExtraItemsProposed", new { addedPaisa = 35050 }, "extras_proposed", ""),
            ("ExtraItemsDecided", new { approved = true }, "", "extras_decided"),
            ("ExtraItemsDecided", new { approved = false }, "", "extras_decided"),
            ("BookingCompleted", null, "booking_completed", "booking_completed"),
            ("BookingCancelled", new { by = "customer" }, "", "booking_cancelled"),
            ("BookingCancelled", new { by = "provider" }, "booking_cancelled", ""),
        };
        foreach (var (name, extra, toCustomer, toProvider) in cases)
        {
            await Deliver($"booking.{name}", Parties(extra));
            foreach (var (want, side, token) in new[] { (toCustomer, "customer", customer), (toProvider, "provider", provider) }.Where(c => c.Item1.Length > 0))
            {
                Assert.Equal($"{name} {want}", $"{name} {Types(await Inbox(side, token, "?limit=1"))[0]}");
            }
        }
        var prov = await Inbox("provider", provider);
        var first = prov.GetProperty("items")[0];
        Assert.Equal("Booking PAO-100001 was cancelled.", (await Inbox("provider", provider, "?limit=1")).GetProperty("items")[0].GetProperty("body").GetString());
        Assert.Equal(world.Booking.ToString(), first.GetProperty("bookingId").GetString());
        var bodies = (await Inbox("customer", customer)).GetProperty("items").EnumerateArray().Select(i => i.GetProperty("body").GetString()).ToList();
        Assert.Contains("আপনার সেবাদাতা ৳350 মূল্যের আইটেম যোগ করেছেন। অনুমোদন বা বাতিল করুন।", bodies);
        Assert.Contains("The customer approved the extra items on booking PAO-100001.", prov.GetProperty("items").EnumerateArray().Select(i => i.GetProperty("body").GetString()));
        Assert.Contains("Fan install in Gulshan — answer before the time runs out.", prov.GetProperty("items").EnumerateArray().Select(i => i.GetProperty("body").GetString()));
        await BrokenAndUnknown(prov.GetProperty("items").GetArrayLength());
    }

    private async Task BrokenAndUnknown(int before)
    {
        foreach (var name in new[] { "booking.BookingAccepted", "verification.DocumentExpired", "identity.AccountDeleted" })
        {
            await Assert.ThrowsAsync<EventDeliveryException>(() => Deliver(name, "nope"));
        }
        await Deliver("booking.BookingAccepted", new { bookingId = Guid.NewGuid(), customerId = world.Customer });
        await Deliver("booking.BookingRequested", new { bookingId = Guid.NewGuid(), providerId = world.Provider });
        Assert.Equal(before, (await Inbox("provider", provider)).GetProperty("items").GetArrayLength());
        await Assert.ThrowsAsync<EventDeliveryException>(() => Deliver("booking.BookingRequested", new { bookingId = world.BrokenBooking, providerId = world.Provider }));
    }

    [Fact]
    public async Task Providers_hear_about_verification_and_reporters_about_complaints()
    {
        var events = new (string Name, object Payload)[]
        {
            ("verification.ProviderLevelChanged", new { providerId = world.Provider, from = 0, to = 1 }),
            ("verification.DocumentRejected", new { providerId = world.Provider, item = "selfie", reason = "Blurred" }),
            ("verification.DocumentExpired", new { providerId = world.Provider, item = "police_clearance" }),
            ("verification.DocumentExpiring", new { providerId = world.Provider, item = "unknown_item", daysLeft = 7 }),
            ("verification.Level2SessionScheduled", new { providerId = world.Provider, scheduledAt = "2026-10-12T10:00:00Z", location = "Gulshan" }),
            ("verification.DocumentRejected", new { providerId = world.BanglaProvider, item = "selfie", reason = "x" }),
            ("admin.ComplaintResolved", new { reporterId = world.Customer, reporterRole = "customer", ticketNumber = "T-1" }),
            ("admin.ComplaintResolved", new { reporterId = world.Provider, reporterRole = "provider", ticketNumber = "T-2" }),
        };
        foreach (var (name, payload) in events)
        {
            await Deliver(name, payload);
        }
        var bodies = (await Inbox("provider", provider)).GetProperty("items").EnumerateArray().Select(i => i.GetProperty("body").GetString()).Reverse().ToList();
        Assert.Equal(
            ["Your verification level is now 1.", "Your selfie was not approved: Blurred", "Your police clearance has expired. Renew it to receive bookings again.",
             "Your  expires in 7 days.", "Your Level 2 session is at Gulshan on 2026-10-12T10:00:00Z.", "Your report T-2 has been resolved."],
            bodies);
        var bangla = await Inbox("provider", api.Token(world.BanglaProvider, "provider"));
        Assert.Equal("আপনার সেলফি অনুমোদিত হয়নি: x", bangla.GetProperty("items")[0].GetProperty("body").GetString());
        Assert.Equal("আপনার অভিযোগ T-1-এর সমাধান হয়েছে।", (await Inbox("customer", customer)).GetProperty("items")[0].GetProperty("body").GetString());
        await Assert.ThrowsAsync<EventDeliveryException>(() => Deliver("admin.ComplaintResolved", new { reporterId = world.Customer, reporterRole = "admin" }));
    }

    [Fact]
    public async Task The_contract_stores_once_pushes_live_devices_and_drops_dead_ones()
    {
        foreach (var token in new[] { "tok-live-device-1", "invalid-device-1", "broken-device-1" })
        {
            Assert.Equal(HttpStatusCode.NoContent, (await api.Call(HttpMethod.Put, "/v1/customer/device-token", customer, new { token, platform = "android" })).Status);
        }
        using var scope = api.Services.CreateScope();
        var notifications = scope.ServiceProvider.GetRequiredService<INotificationSharedService>();
        var m = new NotificationMessage
        {
            RecipientId = world.Customer,
            App = NotificationApp.Customer,
            Language = "en",
            Template = "complaint_resolved",
            Data = new Dictionary<string, string> { ["ticket"] = "1001" },
            Channels = [],
            DedupeKey = "k1",
        };
        await notifications.Send(m, CancellationToken.None);
        await notifications.Send(m, CancellationToken.None);
        var pushed = Assert.Single(api.Services.GetRequiredService<IPushCapture>().SentTo("tok-live-device-1"));
        Assert.Equal(("Report resolved", "Your report 1001 has been resolved.", "complaint_resolved"), (pushed.Title, pushed.Body, pushed.Data["type"]));
        var db = scope.ServiceProvider.GetRequiredService<PaoDbContext>();
        var tokens = await db.Database.SqlQuery<string>($"""SELECT token AS "Value" FROM notification.device_tokens WHERE account_id = {world.Customer} ORDER BY token""").ToListAsync();
        Assert.Equal(["broken-device-1", "tok-live-device-1"], tokens);
        await notifications.Send(m with { DedupeKey = "k2", BookingId = world.Booking }, CancellationToken.None);
        Assert.Equal(world.Booking.ToString(), api.Services.GetRequiredService<IPushCapture>().SentTo("tok-live-device-1")[^1].Data["bookingId"]);
        foreach (var bad in new[] { m with { Template = "nope" }, m with { DedupeKey = string.Empty }, m with { App = "admin" } })
        {
            Assert.Equal(NotificationReasons.Invalid, (await Assert.ThrowsAsync<DomainException>(() => notifications.Send(bad, CancellationToken.None))).Reason);
        }
    }

    [Fact]
    public async Task Read_state_pages_and_erasure_work_per_recipient_and_app()
    {
        foreach (var name in new[] { "BookingAccepted", "ProviderOnTheWay", "BookingStarted" })
        {
            await Deliver($"booking.{name}", Parties());
        }
        await Deliver("booking.BookingCompleted", Parties());
        var all = await Inbox("customer", customer);
        Assert.Equal(4, all.GetProperty("unreadCount").GetInt32());
        var page = await Inbox("customer", customer, "?limit=3");
        Assert.Equal(3, page.GetProperty("items").GetArrayLength());
        var next = await Inbox("customer", customer, $"?limit=3&cursor={page.GetProperty("nextCursor").GetString()}");
        Assert.Equal(["booking_accepted"], Types(next));
        Assert.False(next.TryGetProperty("nextCursor", out _));
        Assert.Equal(HttpStatusCode.UnprocessableEntity, (await api.Call(HttpMethod.Get, "/v1/provider/notifications?cursor=%25", provider)).Status);
        var id = all.GetProperty("items")[0].GetProperty("id").GetString();
        Assert.Equal(HttpStatusCode.NotFound, (await api.Call(HttpMethod.Post, $"/v1/provider/notifications/{id}/read", provider)).Status);
        Assert.Equal(HttpStatusCode.NoContent, (await api.Call(HttpMethod.Post, $"/v1/customer/notifications/{id}/read", customer)).Status);
        Assert.Equal(HttpStatusCode.NoContent, (await api.Call(HttpMethod.Post, $"/v1/customer/notifications/{id}/read", customer)).Status);
        Assert.Equal(3, (await Inbox("customer", customer)).GetProperty("unreadCount").GetInt32());
        Assert.False((await Inbox("customer", customer)).GetProperty("items")[1].GetProperty("read").GetBoolean());
        Assert.Equal(HttpStatusCode.NoContent, (await api.Call(HttpMethod.Post, "/v1/customer/notifications/read-all", customer)).Status);
        Assert.Equal(HttpStatusCode.NoContent, (await api.Call(HttpMethod.Post, "/v1/provider/notifications/read-all", provider)).Status);
        Assert.Equal(0, (await Inbox("provider", provider)).GetProperty("unreadCount").GetInt32());
        Assert.Equal(HttpStatusCode.NoContent, (await api.Call(HttpMethod.Put, "/v1/provider/device-token", provider, new { token = "provider-device-1", platform = "ios" })).Status);
        await Deliver("identity.AccountDeleted", new { accountId = world.Customer });
        Assert.Equal(0, (await Inbox("customer", customer)).GetProperty("items").GetArrayLength());
        Assert.Equal(["booking_completed"], Types(await Inbox("provider", provider)));
    }
}
