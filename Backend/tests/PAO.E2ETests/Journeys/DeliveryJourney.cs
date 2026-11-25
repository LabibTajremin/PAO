using System.Globalization;
using System.Text.Json.Nodes;
using PAO.E2ETests.Support;
using static PAO.E2ETests.Support.Actors;
using static PAO.E2ETests.Support.Bookings;
using static PAO.E2ETests.Support.Client;
using static PAO.E2ETests.Support.Json;

namespace PAO.E2ETests.Journeys;

/// <summary>
/// Scheduled delivery end to end (P25, ADR-0041): office lunch ordered for three days, one
/// skipped, each due date made into a booking at its cutoff and paid in cash on delivery.
/// The cutoff sweep runs through the `/__test/booking/deliveries` hook at chosen times.
/// </summary>
public sealed class DeliveryJourney : Journey
{
    private static readonly TimeSpan Dhaka = TimeSpan.FromHours(6);

    private static DateOnly DhakaToday => DateOnly.FromDateTime(DateTimeOffset.UtcNow.ToOffset(Dhaka).DateTime);

    private static string Iso(DateOnly d) => d.ToString("yyyy-MM-dd", CultureInfo.InvariantCulture);

    // 20:01 in Dhaka on the day before `date`: just past the office-lunch cutoff.
    private static async Task<int> SweepAfterCutoffOf(DateOnly date)
    {
        var at = new DateTimeOffset(date.AddDays(-1).ToDateTime(new TimeOnly(20, 1)), Dhaka).ToUniversalTime();
        var r = await Send("POST", $"/__test/booking/deliveries?at={Uri.EscapeDataString(at.ToString("yyyy-MM-dd'T'HH:mm:ss'Z'", CultureInfo.InvariantCulture))}", null);
        Assert.Equal(204, r.Status);
        return r.Status;
    }

    private static async Task<JsonObject> Day(Session c, string id, DateOnly date) =>
        Obj(List((await Get($"/v1/customer/subscriptions/{id}", c)).Expect(200)["upcoming"]).Single(d => Str(d!["date"]) == Iso(date)));

    // The sweep at the first cutoff books the first date; the merchant delivers it and
    // takes the cash, and PAO's commission is charged for that one delivery.
    private static async Task DeliverFirst(Session c, Partner p, string id, DateOnly first)
    {
        await SweepAfterCutoffOf(first);
        var booked = await Day(c, id, first);
        var bookingId = Str(booked["bookingId"]);
        var code = await StartCode(c, bookingId);
        await MustJob(p, bookingId, "on-the-way");
        await MustJob(p, bookingId, "arrived");
        await MustJob(p, bookingId, "start", new { code });
        Has(await MustJob(p, bookingId, "complete", new { cashReceived = true }), ("status", "completed"), ("paymentMethod", "cash_on_delivery"));
        await Eventually(Seconds(10), "delivery reminder pushed to the merchant", () => Pushed(p.PushToken, "deliveries_tomorrow", bookingId));
        await Eventually(Seconds(10), "commission charged for the delivery", async () =>
            List((await Get("/v1/provider/billing/ledger", p.Session)).Expect(200)["items"]).Any(e => Str(e!["bookingId"]) == bookingId));
    }

    [Fact]
    public async Task Office_lunch_skips_a_day_and_each_delivery_is_paid_in_cash()
    {
        var customer = await CustomerAt(PhoneFor("017", 81));
        var lunch = await Providers.CatalogService(customer.Session, "Office lunch");
        var p = await OnlineProvider(82, lunch.Id);
        var first = DhakaToday.AddDays(2);
        var order = new
        {
            providerId = p.Id,
            serviceId = lunch.Id,
            addressId = customer.Address,
            items = new[] { new { subServiceId = lunch.First.Id, quantity = 2 } },
            pattern = "daily",
            window = new { start = "12:00", end = "13:00" },
            startDate = Iso(first),
            count = 3,
        };
        var key = new Dictionary<string, string> { ["Idempotency-Key"] = $"e2e-lunch-{customer.Session.Id}" };
        var created = (await Call(Stack.Current.Api, "POST", "/v1/customer/subscriptions", order, customer.Session, key)).Expect(201);
        var id = Str(created["id"]);
        Has(created, ("status", "requested"), ("total", 2 * lunch.First.Price));
        Has((await Send("POST", $"/v1/provider/subscriptions/{id}/accept", null, p.Session)).Expect(200), ("status", "active"));
        var skip = await Send("PUT", $"/v1/customer/subscriptions/{id}/deliveries/{Iso(first.AddDays(1))}", new { skip = true }, customer.Session);
        Has(skip.Expect(200), ("status", "skipped"));

        await DeliverFirst(customer.Session, p, id, first);
        Assert.Equal("delivered", Str((await Day(customer.Session, id, first))["status"]));

        await SweepAfterCutoffOf(first.AddDays(1));
        Assert.True(Missing((await Day(customer.Session, id, first.AddDays(1)))["bookingId"]));
        await SweepAfterCutoffOf(first.AddDays(2));
        var last = await Day(customer.Session, id, first.AddDays(2));
        Assert.False(Missing(last["bookingId"]));
        Has((await Get($"/v1/customer/subscriptions/{id}", customer.Session)).Expect(200), ("status", "finished"));
    }
}
