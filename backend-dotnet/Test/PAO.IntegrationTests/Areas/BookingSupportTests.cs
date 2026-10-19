using System.Net;
using System.Text.Json;
using PAO.Core.Areas.Booking.Services.Shared;
using PAO.Lib.Areas.Booking;
using PAO.Lib.Errors;
using PAO.TestKit;
using static PAO.IntegrationTests.Areas.BookingWorld;

namespace PAO.IntegrationTests.Areas;

/// <summary>Ownership, the contract, earnings paging, the admin monitor and failures.</summary>
public sealed class BookingSupportTests : IAsyncLifetime
{
    private PeopleApi api = null!;

    private string url = string.Empty;

    // Each test gets its own database: the counts it checks are its own.
    public async ValueTask InitializeAsync() => api = await PeopleApi.Start(url = await TestDatabases.CreateMigrated());

    public async ValueTask DisposeAsync()
    {
        await api.DisposeAsync();
        await TestDatabases.Drop(url);
    }

    private static string? Code((HttpStatusCode, JsonElement Body) r) => PeopleApi.Code(r.Body);

    [Fact]
    public async Task Hides_the_booking_serves_the_contract_and_pages_earnings()
    {
        var w = await Create(api);
        var photo = await api.Avatar(w.Provider.Token, "provider");
        Assert.Equal(HttpStatusCode.OK, (await w.AsProvider(HttpMethod.Put, "/v1/provider/profile", new { language = "bn", photoMediaId = photo })).Status);
        var near = await w.AsCustomer(HttpMethod.Get, $"/v1/customer/providers/nearby?serviceId={Electrician}&subServiceId={Fan}&quantity=1&addressId={w.AddressId}");
        Assert.True(near.Body.GetProperty("items")[0].TryGetProperty("photoUrl", out _));
        var id = await w.Book("owner-1");
        var other = await VerifiedProvider(api, "01712345688", Electrician);
        foreach (var action in new[] { "reject", "on-the-way", "arrived" })
        {
            Assert.Equal(HttpStatusCode.NotFound, (await w.Job(id, action, new { reason = "busy" }, other.Token)).Status);
        }
        Assert.Equal(HttpStatusCode.NotFound, (await api.Call(HttpMethod.Get, $"/v1/provider/jobs/{id}/receipt", other.Token)).Status);
        var stranger = api.Api.Token(Guid.NewGuid(), "customer");
        Assert.Equal(HttpStatusCode.NotFound, (await api.Call(HttpMethod.Get, $"/v1/customer/bookings/{id}/start-code", stranger)).Status);
        Assert.Equal("BOOKING_INVALID_TRANSITION", Code(await w.Job(id, "extras", new { items = new[] { new { subServiceId = Fan, quantity = 1 } } })));
        var b = await w.Contract<IBookingSharedService, BookingDetails>(s => s.GetBooking(id, CancellationToken.None));
        Assert.Equal(("requested", "Nusrat Jahan"), (b.Status, b.CustomerName));
        Assert.Matches("^PAO-\\d+$", b.Number);
        var missing = await Assert.ThrowsAsync<DomainException>(() => w.Contract<IBookingSharedService, BookingDetails>(s => s.GetBooking(Guid.NewGuid(), CancellationToken.None)));
        Assert.Equal(BookingErrors.NotFound, missing.Reason);
        Assert.Single(await w.Contract<IBookingSharedService, IReadOnlyList<BookingSummary>>(s => s.ListRecentBookings(w.Provider.Id, 5, CancellationToken.None)));
        await w.AsCustomer(HttpMethod.Post, $"/v1/customer/bookings/{id}/cancel", new { reason = "other", note = "not needed" });
        foreach (var key in new[] { "earn-1", "earn-2" })
        {
            await w.Completed(key);
        }
        var page = (await w.AsProvider(HttpMethod.Get, "/v1/provider/earnings/jobs?limit=1")).Body;
        Assert.Equal(1, page.GetProperty("items").GetArrayLength());
        var next = await w.AsProvider(HttpMethod.Get, $"/v1/provider/earnings/jobs?limit=1&cursor={page.GetProperty("nextCursor").GetString()}");
        Assert.Equal(1, next.Body.GetProperty("items").GetArrayLength());
        Assert.Equal(0, (await w.AsProvider(HttpMethod.Get, "/v1/provider/earnings/summary?period=day&date=2026-01-01")).Body.GetProperty("jobs").GetInt32());
        Assert.Equal(HttpStatusCode.OK, (await w.AsProvider(HttpMethod.Get, "/v1/provider/earnings/jobs?from=2026-01-01&to=2026-12-31&limit=1")).Status);
        Assert.Equal(31, (await w.AsProvider(HttpMethod.Get, "/v1/provider/earnings/summary?period=month&date=2026-10-08")).Body.GetProperty("buckets").GetArrayLength());
        Assert.Equal(HttpStatusCode.UnprocessableEntity, (await w.AsCustomer(HttpMethod.Get, "/v1/customer/bookings?tab=past&cursor=%25")).Status);
        await w.AsProvider(HttpMethod.Post, "/v1/provider/presence/offline");
        Assert.Equal("PROVIDER_UNAVAILABLE", Code(await w.Request("offline")));
        await api.Sql($"UPDATE catalog.services SET published = false WHERE id = '{Electrician}'");
        Assert.Equal("PROVIDER_UNAVAILABLE", Code(await w.AsCustomer(HttpMethod.Get, $"/v1/customer/providers/nearby?serviceId={Electrician}&subServiceId={Fan}&quantity=1&addressId={w.AddressId}")));
    }

    [Fact]
    public async Task Monitors_bookings_for_support()
    {
        var w = await Create(api, "01712345691", "01812345691");
        var done = await w.Completed("monitor-done");
        var (customer, address) = await NewCustomer(api, "01812345692");
        var open = await new BookingWorldFor(w, customer, address).Book("monitor-open");
        var token = api.Api.Token("support_agent");
        async Task<int> Count(string q) => (await api.Call(HttpMethod.Get, $"/v1/admin/bookings{q}", token)).Body.GetProperty("items").GetArrayLength();
        var day = PAO.Core.Areas.Booking.Services.EarningsCalendar.DhakaDay(api.Clock.Now);
        string Iso(DateOnly d) => d.ToString("yyyy-MM-dd", System.Globalization.CultureInfo.InvariantCulture);
        Assert.Equal(2, await Count(string.Empty));
        Assert.Equal(1, await Count("?status=completed"));
        Assert.Equal(2, await Count($"?serviceId={Electrician}"));
        Assert.Equal(0, await Count($"?serviceId={Guid.NewGuid()}"));
        Assert.Equal(2, await Count("?area=banani"));
        Assert.Equal(0, await Count("?area=Gulshan"));
        Assert.Equal(2, await Count($"?from={Iso(day)}&to={Iso(day)}"));
        Assert.Equal(0, await Count($"?from={Iso(day.AddDays(1))}"));
        Assert.Equal(0, await Count($"?to={Iso(day.AddDays(-1))}"));
        var first = (await api.Call(HttpMethod.Get, "/v1/admin/bookings?limit=1", token)).Body;
        Assert.Equal(open.ToString(), first.GetProperty("items")[0].GetProperty("id").GetString());
        Assert.Contains(" → ", first.GetProperty("items")[0].GetProperty("counterpartName").GetString(), StringComparison.Ordinal);
        var rest = (await api.Call(HttpMethod.Get, $"/v1/admin/bookings?limit=1&cursor={first.GetProperty("nextCursor").GetString()}", token)).Body;
        Assert.Equal(done.ToString(), rest.GetProperty("items")[0].GetProperty("id").GetString());
        Assert.False(rest.TryGetProperty("nextCursor", out _));
        var d = (await api.Call(HttpMethod.Get, $"/v1/admin/bookings/{open}", token)).Body;
        Assert.True(d.GetProperty("customer").TryGetProperty("phone", out _) && d.GetProperty("provider").TryGetProperty("phone", out _));
        Assert.Equal(HttpStatusCode.NotFound, (await api.Call(HttpMethod.Get, $"/v1/admin/bookings/{Guid.NewGuid()}", token)).Status);
        Assert.Equal(HttpStatusCode.UnprocessableEntity, (await api.Call(HttpMethod.Get, "/v1/admin/bookings?cursor=%25", token)).Status);
        await api.Deliver("identity.AccountDeleted", new { accountId = customer.Id }, api.Bus(true));
        var erased = (await api.Call(HttpMethod.Get, $"/v1/admin/bookings/{open}", token)).Body;
        Assert.Equal(string.Empty, erased.GetProperty("customer").GetProperty("name").GetString());
        await api.Sql("ALTER TABLE booking.booking_items RENAME TO items_gone");
        Assert.Equal(HttpStatusCode.InternalServerError, (await api.Call(HttpMethod.Get, $"/v1/admin/bookings/{open}", token)).Status);
        Assert.Equal(HttpStatusCode.InternalServerError, (await w.Request("without-items")).Status);
        await api.Sql("ALTER TABLE booking.items_gone RENAME TO booking_items");
    }

    /// <summary>The same world booked by another customer.</summary>
    private sealed class BookingWorldFor(BookingWorld w, (Guid Id, string Token) customer, Guid address)
    {
        public async Task<Guid> Book(string key)
        {
            var body = new Dictionary<string, object?> { ["addressId"] = address };
            var r = await w.Request(key, body, customer.Token);
            Assert.Equal(HttpStatusCode.Created, r.Status);
            return Guid.Parse(r.Body.GetProperty("id").GetString()!);
        }
    }
}
