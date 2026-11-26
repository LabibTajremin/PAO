using System.Globalization;
using System.Text.Json.Nodes;
using PAO.E2ETests.Support;
using static PAO.E2ETests.Support.Actors;
using static PAO.E2ETests.Support.Client;
using static PAO.E2ETests.Support.Providers;

namespace PAO.E2ETests.Journeys;

public sealed class ExpiryJourney : Journey
{
    private static string ItemStatus(JsonObject status, string item) =>
        Json.List(status["items"]).FirstOrDefault(it => Json.Str(it["type"]) == item)?["status"]?.ToString() ?? string.Empty;

    private static async Task<JsonObject> Verification(Session p) => (await Get("/v1/provider/verification", p)).Expect(200);

    [Fact]
    public async Task Expiry_police_clearance_lapses_then_a_renewal_restores_the_provider()
    {
        var c = await NewCustomer(PhoneFor("017", 31));
        var svc = await Service(c, "Electrician");
        // Issued a day short of the validity period, so it lapses tomorrow; every other
        // journey's clearance is a month old and stays valid past the sweep below.
        // Counted from today in Dhaka, where the API dates certificates: after 18:00 UTC
        // the UTC date is a day behind and the clearance would already be a year old.
        var dhakaToday = DateTimeOffset.UtcNow.AddHours(6);
        var p = await EnrolledProvider(PhoneFor("018", 32), svc.Id, dhakaToday.AddDays(-364));
        Task<bool> Found() => Nearby(c, svc.Id, svc.Sub, p.Id!);
        await Approve(p, Items);
        await GoOnline(p);
        OnCleanup(() => Send("POST", "/v1/provider/presence/offline", null, p));
        await Eventually(Seconds(10), "provider in nearby search", Found);

        var sweepAt = DateTimeOffset.UtcNow.AddDays(3).UtcDateTime.ToString("yyyy-MM-dd'T'HH:mm:ss'Z'", CultureInfo.InvariantCulture);
        var sweep = await Send("POST", $"/__test/verification/expire?at={Uri.EscapeDataString(sweepAt)}", null);
        Assert.Equal(204, sweep.Status);
        var lapsed = await Verification(p);
        Json.Has(lapsed, ("level", 0), ("canReceiveBookings", false));
        Assert.Equal("expired", ItemStatus(lapsed, "police_clearance"));
        await Eventually(Seconds(10), "provider hidden from search", async () => !await Found());
        Assert.NotEqual(200, await TryOnline(p));

        var renewed = new { mediaId = await Upload(p, "provider", "police_clearance"), issueDate = DateOnlyOf(DateTimeOffset.UtcNow.AddDays(-7)) };
        (await Send("PUT", "/v1/provider/enrolment/police-clearance", renewed, p)).Expect(200);
        Assert.Equal("pending", ItemStatus(await Verification(p), "police_clearance"));
        await Approve(p, "police_clearance");
        Json.Has(await Verification(p), ("level", 1), ("canReceiveBookings", true));
        await GoOnline(p);
        await Eventually(Seconds(10), "provider back in nearby search", Found);
    }
}
