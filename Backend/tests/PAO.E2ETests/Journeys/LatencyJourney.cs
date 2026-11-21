using System.Diagnostics;
using PAO.E2ETests.Support;
using static PAO.E2ETests.Support.Actors;
using static PAO.E2ETests.Support.Bookings;
using static PAO.E2ETests.Support.Client;

namespace PAO.E2ETests.Journeys;

public sealed class LatencyJourney(ITestOutputHelper output) : Journey
{
    // PRD §11: a booking request reaches the provider's phone within 3 seconds. Measured
    // from the create call returning to the push showing up in the worker's capture, over
    // sequential requests.
    [Fact]
    public async Task Latency_a_request_reaches_the_provider_within_3_s()
    {
        const int samples = 10;
        const int limitMs = 3000;
        var (c, address) = await CustomerAt(PhoneFor("017", 61));
        var svc = await Providers.CatalogService(c, "Electrician");
        var p = await OnlineProvider(62, svc.Id);
        var order = new Order(c, address, p.Id, svc.Id);
        var took = new List<double>();
        for (var i = 0; i < samples; i++)
        {
            var id = Json.Str((await BookAsap(order, new Line(svc.First, 1)))["id"]);
            var clock = Stopwatch.StartNew();
            while (!await Pushed(p.PushToken, "booking_requested", id))
            {
                if (clock.ElapsedMilliseconds > 2 * limitMs)
                {
                    throw new TimeoutException($"no push for {id} after {2 * limitMs} ms");
                }
                await Task.Delay(50);
            }
            took.Add(clock.Elapsed.TotalMilliseconds);
            // The customer may hold one open request per provider; close this one first.
            (await Send("POST", $"/v1/customer/bookings/{id}/cancel", new { reason = "booked_by_mistake" }, c)).Expect(200);
        }
        // With ten samples the 95th percentile is the slowest one.
        var p95 = took.Max();
        output.WriteLine($"request → push ms: {string.Join(", ", took.Select(t => Math.Round(t)))} (p95 {Math.Round(p95)})");
        Assert.True(p95 < limitMs, $"p95 {p95} ms is not under {limitMs} ms");
    }
}
