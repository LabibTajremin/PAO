using System.Globalization;
using PAO.E2ETests.Support;
using static PAO.E2ETests.Support.Actors;
using static PAO.E2ETests.Support.Bookings;
using static PAO.E2ETests.Support.Client;
using static PAO.E2ETests.Support.Json;

namespace PAO.E2ETests.Journeys;

public sealed class BookingJourney : Journey
{
    // A booking between a customer and a provider.
    private sealed record Booked(Session C, Partner P, string Id);

    // Books two of `fan` with the provider, checks the provider was paged and that contact
    // details are shared only after acceptance; returns the booking ID.
    private static async Task<string> RequestAndAccept(Order order, Partner p, Sub fan)
    {
        var c = order.Customer;
        var b = await BookAsap(order, new Line(fan, 2));
        var id = Str(b["id"]);
        Has(b, ("total", 2 * fan.Price), ("timing", "asap"));
        await Eventually(Seconds(10), "request pushed to the provider", () => Pushed(p.PushToken, "booking_requested", id));
        var request = (await Get($"/v1/provider/jobs/{id}", p.Session)).Expect(200);
        Assert.True(Missing(Obj(request["address"])["line1"]));
        Assert.True(Missing(Obj(request["customer"])["phone"]));
        var early = await Get($"/v1/customer/bookings/{id}/start-code", c);
        Assert.Equal("BOOKING_INVALID_TRANSITION", early.Code());

        var accepted = await MustJob(p, id, "accept");
        Assert.Equal("accepted", Str(accepted["status"]));
        Assert.False(Missing(Obj(accepted["address"])["line1"]));
        Assert.False(Missing(Obj(accepted["customer"])["phone"]));
        var seen = (await Get($"/v1/customer/bookings/{id}", c)).Expect(200);
        Assert.Equal("accepted", Str(seen["status"]));
        Assert.False(Missing(Obj(seen["provider"])["phone"]));
        return id;
    }

    // Walks on the way → arrived, enters two wrong start codes, then the right one.
    private static async Task ArriveAndStartAfterTwoWrongCodes(Session c, Partner p, string id)
    {
        var code = await StartCode(c, id);
        await MustJob(p, id, "on-the-way");
        Assert.Equal("on_the_way", await CustomerStatus(c, id));
        await MustJob(p, id, "arrived");
        var n = int.Parse(code, CultureInfo.InvariantCulture);
        foreach (var i in new[] { 1, 2 })
        {
            var wrong = ((n + i) % 10000).ToString("D4", CultureInfo.InvariantCulture);
            Assert.Equal("START_CODE_INVALID", (await Job(p, id, "start", new { code = wrong })).Code());
        }
        Assert.Equal("arrived", await CustomerStatus(c, id));
        Assert.Equal("in_progress", Str((await MustJob(p, id, "start", new { code }))["status"]));
    }

    // The provider proposes one extra item and the customer approves it; completing is
    // refused while the proposal is pending. Returns the new total.
    private static async Task<long> AddApprovedExtras(Booked bk, long before, Sub extra)
    {
        var proposed = await MustJob(bk.P, bk.Id, "extras", new { items = Lines(new Line(extra, 1)) });
        var pending = Obj(proposed["pendingExtras"]);
        var total = before + extra.Price;
        Has(pending, ("addedTotal", extra.Price), ("newTotal", total), ("status", "pending"));
        var early = await Job(bk.P, bk.Id, "complete", new { cashReceived = true });
        Assert.Equal("EXTRAS_PENDING", early.Code());
        var decision = new { proposalId = Str(pending["id"]), approve = true };
        var decided = (await Send("POST", $"/v1/customer/bookings/{bk.Id}/extras/decision", decision, bk.C)).Expect(200);
        Assert.Equal(total, Num(decided["total"]));
        Assert.Equal(2, List(decided["items"]).Count);
        return total;
    }

    // Posts a review once the booking is reviewable: the rating module learns of the
    // completion from the worker's relay a moment after the API answered.
    private static Task Review(Session s, string path, object body) =>
        Eventually(Seconds(10), "review accepted", async () =>
        {
            var r = await Send("POST", path, body, s);
            if (r.Status != 201 && r.Code() != "REVIEW_NOT_ALLOWED")
            {
                throw new InvalidOperationException($"review {path}: {r.Status} {r.Body}");
            }
            return r.Status == 201;
        });

    // Each side reviews the other; the provider's rating follows.
    private static async Task RateBothWays(Session c, Partner p, string id)
    {
        var customerReview = $"/v1/customer/bookings/{id}/review";
        await Review(c, customerReview, new { stars = 5, tags = new[] { "on_time", "professional" }, comment = "Fixed the fan quickly." });
        await Review(p.Session, $"/v1/provider/jobs/{id}/review", new { stars = 4, tags = new[] { "polite", "paid_promptly" } });
        Assert.Equal(409, (await Send("POST", customerReview, new { stars = 1 }, c)).Status);
        Has((await Get($"/v1/customer/bookings/{id}", c)).Expect(200), ("reviewedByMe", true));
        await Eventually(Seconds(10), "provider rating updated", async () =>
        {
            var r = (await Get("/v1/provider/rating", p.Session)).Expect(200);
            return Num(r["count"]) == 1 && r["average"]!.GetValue<decimal>() == 5;
        });
    }

    // Compares both receipts with the booked and the extra lines.
    private static async Task CheckReceipts(Booked bk, long total, Line[] ls)
    {
        foreach (var (who, path) in new[] { (bk.C, $"/v1/customer/bookings/{bk.Id}/receipt"), (bk.P.Session, $"/v1/provider/jobs/{bk.Id}/receipt") })
        {
            var rc = (await Get(path, who)).Expect(200);
            Has(rc, ("total", total), ("paymentMethod", "cash_on_delivery"), ("providerName", "Rahim Uddin"), ("customerName", "Nusrat Jahan"));
            var got = List(rc["items"]);
            Assert.Equal(2, got.Count);
            for (var i = 0; i < got.Count; i++)
            {
                var l = ls[i];
                Has(got[i], ("subServiceId", l.Sub.Id), ("quantity", l.Quantity), ("extra", i > 0), ("unitPrice", l.Sub.Price), ("total", l.Sub.Price * l.Quantity));
            }
        }
    }

    // The completed job is the provider's only earning.
    private static async Task CheckEarnings(Partner p, string id, long total)
    {
        var sum = (await Get("/v1/provider/earnings/summary?period=week", p.Session)).Expect(200);
        Has(sum, ("total", total), ("jobs", 1));
        Assert.Equal(7, List(sum["buckets"]).Count);
        var jobs = List((await Get("/v1/provider/earnings/jobs", p.Session)).Expect(200)["items"]);
        Assert.Single(jobs);
        Has(jobs[0], ("bookingId", id), ("total", total));
    }

    [Fact]
    public async Task Booking_from_request_to_receipt_with_extras_and_ratings()
    {
        var (c, address) = await CustomerAt(PhoneFor("017", 11));
        var electrician = await Providers.CatalogService(c, "Electrician");
        Assert.True(electrician.Subs.Count >= 2, $"electrician needs two sub-services for extras: {electrician}");
        var (fan, extra) = (electrician.Subs[0], electrician.Subs[1]);
        var p = await OnlineProvider(12, electrician.Id);
        await Eventually(Seconds(10), "provider in nearby search", () => Providers.Nearby(c, electrician.Id, fan.Id, p.Id));
        var order = new Order(c, address, p.Id, electrician.Id);

        var id = await RequestAndAccept(order, p, fan);
        await ArriveAndStartAfterTwoWrongCodes(c, p, id);
        var total = await AddApprovedExtras(new Booked(c, p, id), 2 * fan.Price, extra);

        var unpaid = await Job(p, id, "complete", new { cashReceived = false });
        Assert.Equal("CASH_CONFIRMATION_REQUIRED", unpaid.Code());
        Has(await MustJob(p, id, "complete", new { cashReceived = true }), ("status", "completed"), ("total", total));
        await RateBothWays(c, p, id);
        await CheckReceipts(new Booked(c, p, id), total, [new Line(fan, 2), new Line(extra, 1)]);
        await CheckEarnings(p, id, total);
    }
}
