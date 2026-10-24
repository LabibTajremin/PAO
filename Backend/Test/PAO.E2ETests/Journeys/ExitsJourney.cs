using PAO.E2ETests.Support;
using static PAO.E2ETests.Support.Actors;
using static PAO.E2ETests.Support.Bookings;
using static PAO.E2ETests.Support.Client;

namespace PAO.E2ETests.Journeys;

public sealed class ExitsJourney : Journey
{
    private static readonly object CancelBody = new { reason = "changed_mind" };

    // A customer next to an online electrician, ready to book.
    private sealed record World(Session C, Partner P, Offer Svc, Order Order)
    {
        public async Task<string> Book() => Json.Str((await BookAsap(Order, new Line(Svc.First, 1)))["id"]);
    }

    private static async Task<World> NewWorld(int n)
    {
        var (c, address) = await CustomerAt(PhoneFor("017", n));
        var svc = await Providers.CatalogService(c, "Electrician");
        var p = await OnlineProvider(n + 1, svc.Id);
        return new World(c, p, svc, new Order(c, address, p.Id, svc.Id));
    }

    [Fact]
    public async Task Booking_provider_rejects_and_the_customer_sees_it()
    {
        var w = await NewWorld(21);
        var id = await w.Book();
        Assert.Equal(422, (await Job(w.P, id, "reject", new { })).Status);
        Json.Has(await MustJob(w.P, id, "reject", new { reason = "too_far" }), ("status", "rejected"));
        var seen = (await Get($"/v1/customer/bookings/{id}", w.C)).Expect(200);
        Json.Has(seen, ("status", "rejected"), ("cancellable", false));
        Assert.Equal("BOOKING_INVALID_TRANSITION", (await Job(w.P, id, "accept")).Code());
        // A rejected request is closed, so the customer may ask the same provider again.
        await w.Book();
    }

    [Fact]
    public async Task Booking_an_unanswered_request_times_out()
    {
        var w = await NewWorld(23);
        await SetSetting("booking.accept_timeout_asap_seconds", "1");
        var id = await w.Book();
        // The worker sweeps expired requests every 15 seconds.
        await Eventually(Seconds(40), "request timed out", async () => await CustomerStatus(w.C, id) == "timed_out");
        Assert.Equal("BOOKING_INVALID_TRANSITION", (await Job(w.P, id, "accept")).Code());
        await Eventually(Seconds(10), "missed request pushed", () => Pushed(w.P.PushToken, "request_missed", id));
    }

    [Fact]
    public async Task Booking_the_customer_cancels_before_the_start()
    {
        var w = await NewWorld(25);
        async Task<System.Text.Json.Nodes.JsonObject> Cancel(string id) =>
            (await Send("POST", $"/v1/customer/bookings/{id}/cancel", CancelBody, w.C)).Expect(200);

        var requested = await w.Book();
        Json.Has(await Cancel(requested), ("status", "cancelled"));

        var accepted = await w.Book();
        await MustJob(w.P, accepted, "accept");
        await MustJob(w.P, accepted, "on-the-way");
        Json.Has(await Cancel(accepted), ("status", "cancelled"));
        var providerView = (await Get($"/v1/provider/jobs/{accepted}", w.P.Session)).Expect(200);
        Assert.Equal("cancelled", Json.Str(providerView["status"]));
        await Eventually(Seconds(10), "cancellation pushed", () => Pushed(w.P.PushToken, "booking_cancelled", accepted));
    }

    [Fact]
    public async Task Booking_cancellation_is_blocked_once_started()
    {
        var w = await NewWorld(27);
        var id = await w.Book();
        await MustJob(w.P, id, "accept");
        await StartJob(w.C, w.P, id);

        var r = await Send("POST", $"/v1/customer/bookings/{id}/cancel", CancelBody, w.C);
        Assert.Equal((409, "CANCELLATION_NOT_ALLOWED"), (r.Status, r.Code()));
        Assert.Equal(409, (await Job(w.P, id, "cancel", new { reason = "emergency" })).Status);
        var seen = (await Get($"/v1/customer/bookings/{id}", w.C)).Expect(200);
        Json.Has(seen, ("status", "in_progress"), ("cancellable", false));
        await MustJob(w.P, id, "complete", new { cashReceived = true });
    }
}
