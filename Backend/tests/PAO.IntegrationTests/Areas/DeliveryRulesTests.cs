using System.Net;
using Microsoft.Extensions.DependencyInjection;
using PAO.Core.Areas.Booking.Features.Erasure.Commands;
using PAO.Infrastructure.Testing;
using PAO.Lib.Areas.Catalog;
using PAO.TestKit;
using static PAO.IntegrationTests.Areas.DeliveryFlowTests;

namespace PAO.IntegrationTests.Areas;

/// <summary>What scheduled-delivery orders refuse, what support sees and how an order ends (ADR-0041).</summary>
public sealed class DeliveryRulesTests : IAsyncLifetime
{
    private PeopleApi api = null!;
    private string url = string.Empty;

    public async ValueTask InitializeAsync() => api = await PeopleApi.Start(url = await TestDatabases.CreateMigrated());

    public async ValueTask DisposeAsync()
    {
        await api.DisposeAsync();
        await TestDatabases.Drop(url);
    }

    private static Task<(HttpStatusCode Status, System.Text.Json.JsonElement Body)> Post(BookingWorld w, Dictionary<string, object?> extra, string key) =>
        w.Send(HttpMethod.Post, "/v1/customer/subscriptions", w.Customer.Token, Order(w, extra), "subscription-" + key);

    [Fact]
    public async Task Orders_outside_the_service_rules_are_refused()
    {
        var w = await World(api);
        var cases = new (string Key, Dictionary<string, object?> Extra, string Code)[]
        {
            ("window", new() { ["window"] = new { start = "09:00", end = "10:00" } }, "VALIDATION_FAILED"),
            ("pattern", new() { ["pattern"] = "monthly", ["weekdays"] = null, ["dayOfMonth"] = 6 }, "VALIDATION_FAILED"),
            ("too-many", new() { ["items"] = new[] { new { subServiceId = Box, quantity = 51 } } }, "VALIDATION_FAILED"),
            ("lead", new() { ["startDate"] = "2026-12-03", ["pattern"] = "once", ["weekdays"] = null, ["endDate"] = null }, "VALIDATION_FAILED"),
            ("no-dates", new() { ["weekdays"] = new[] { 5 }, ["endDate"] = "2026-12-10" }, "VALIDATION_FAILED"),
            ("bad-date", new() { ["startDate"] = "6 December" }, "VALIDATION_FAILED"),
            ("on-demand", new() { ["serviceId"] = SeedIds.For("service", "electrician") }, "PROVIDER_UNAVAILABLE"),
        };
        foreach (var (key, extra, code) in cases)
        {
            var refused = await Post(w, extra, key);
            Assert.True(PeopleApi.Code(refused.Body) == code, $"{key}: {refused.Body}");
        }
        Assert.Equal(HttpStatusCode.NotFound, (await w.AsCustomer(HttpMethod.Get, $"/v1/customer/subscriptions/{Guid.NewGuid()}")).Status);
        Assert.Equal("VALIDATION_FAILED", PeopleApi.Code((await w.AsProvider(HttpMethod.Get, "/v1/provider/subscriptions?status=lost")).Body));
        Assert.Equal("VALIDATION_FAILED", PeopleApi.Code((await w.AsProvider(HttpMethod.Get, "/v1/provider/deliveries?from=2026-12-01&to=2027-03-01")).Body));
        Assert.Equal("VALIDATION_FAILED", PeopleApi.Code((await w.AsProvider(HttpMethod.Get, "/v1/provider/deliveries?from=2026-12-10&to=2026-12-01")).Body));
    }

    [Fact]
    public async Task Dates_change_only_as_ordered_and_a_declined_order_stays_declined()
    {
        var w = await World(api);
        var id = (await Post(w, [], "decline")).Body.GetProperty("id").GetString()!;
        var path = $"/v1/customer/subscriptions/{id}/deliveries";
        Assert.Equal("VALIDATION_FAILED", PeopleApi.Code((await w.AsCustomer(HttpMethod.Put, $"{path}/2026-12-06", new { })).Body));
        Assert.Equal(HttpStatusCode.NotFound, (await w.AsCustomer(HttpMethod.Put, $"{path}/2026-12-11", new { skip = true })).Status);
        foreach (var items in new object[]
        {
            new[] { new { subServiceId = SeedIds.For("sub-service", "lunch-box-veg"), quantity = 1 } },
            new[] { new { subServiceId = Box, quantity = 0 } },
            new[] { new { subServiceId = Box, quantity = 1 }, new { subServiceId = Box, quantity = 2 } },
            Array.Empty<object>(),
        })
        {
            Assert.Equal("VALIDATION_FAILED", PeopleApi.Code((await w.AsCustomer(HttpMethod.Put, $"{path}/2026-12-06", new { items })).Body));
        }
        Assert.Equal("skipped", Status(await w.AsCustomer(HttpMethod.Put, $"{path}/2026-12-06", new { skip = true })));
        Assert.Equal("scheduled", Status(await w.AsCustomer(HttpMethod.Put, $"{path}/2026-12-06", new { skip = false })));
        Assert.Equal("BOOKING_INVALID_TRANSITION", PeopleApi.Code((await w.AsCustomer(HttpMethod.Post, $"/v1/customer/subscriptions/{id}/pause")).Body));
        Assert.Equal(HttpStatusCode.UnprocessableEntity, (await w.AsProvider(HttpMethod.Post, $"/v1/provider/subscriptions/{id}/decline", new { reason = "" })).Status);
        var declined = await w.AsProvider(HttpMethod.Post, $"/v1/provider/subscriptions/{id}/decline", new { reason = "too_far", note = "Outside my area" });
        Assert.Equal(("declined", "declined"), (Status(declined), Day(declined.Body, "2026-12-07").GetProperty("status").GetString()));
        Assert.Equal("BOOKING_INVALID_TRANSITION", PeopleApi.Code((await w.AsCustomer(HttpMethod.Put, $"{path}/2026-12-06", new { skip = true })).Body));
        Assert.Equal("BOOKING_INVALID_TRANSITION", PeopleApi.Code((await w.AsProvider(HttpMethod.Post, $"/v1/provider/subscriptions/{id}/decline", new { reason = "busy" })).Body));
        var other = await api.SignIn("01812345699", "customer");
        Assert.Equal(HttpStatusCode.NotFound, (await api.Call(HttpMethod.Get, $"/v1/customer/subscriptions/{id}", other.Token)).Status);
    }

    [Fact]
    public async Task A_counted_order_finishes_with_its_last_delivery_and_support_sees_everything()
    {
        var w = await World(api);
        var order = await Post(w, new() { ["pattern"] = "daily", ["weekdays"] = null, ["endDate"] = null, ["count"] = 2 }, "counted");
        var id = order.Body.GetProperty("id").GetString()!;
        await w.AsProvider(HttpMethod.Post, $"/v1/provider/subscriptions/{id}/accept");
        using (var scope = api.Services.CreateScope())
        {
            // The e2e hook runs the same sweep as of a chosen time.
            await scope.ServiceProvider.GetRequiredService<IDeliverySweep>().MaterialiseDeliveriesAt(Dhaka(5, 20, 30), CancellationToken.None);
        }
        api.Clock.Now = Dhaka(6, 20, 30);
        Assert.Equal(2, await Sweep(api));
        var admin = api.Api.Token("super_admin");
        var support = await api.Call(HttpMethod.Get, $"/v1/admin/subscriptions/{id}", admin);
        Assert.Equal(("finished", "+8801712345611"), (Status(support), support.Body.GetProperty("provider").GetProperty("phone").GetString()));
        var listed = await api.Call(HttpMethod.Get, "/v1/admin/subscriptions?status=finished", admin);
        Assert.Equal(id, listed.Body.GetProperty("items")[0].GetProperty("id").GetString());
        await w.RefreshTokens("01712345611", "01812345612");
        Assert.Single((await w.AsCustomer(HttpMethod.Get, "/v1/customer/subscriptions")).Body.GetProperty("items").EnumerateArray());
        await w.Send(new EraseBookingSnapshots(w.Customer.Id));
        var erased = await api.Call(HttpMethod.Get, $"/v1/admin/subscriptions/{id}", admin);
        Assert.Equal(string.Empty, erased.Body.GetProperty("customer").GetProperty("name").GetString());
        await w.Send(new EraseBookingSnapshots(w.Provider.Id));
        Assert.Equal(string.Empty, (await api.Call(HttpMethod.Get, $"/v1/admin/subscriptions/{id}", admin)).Body.GetProperty("provider").GetProperty("name").GetString());
    }
}
