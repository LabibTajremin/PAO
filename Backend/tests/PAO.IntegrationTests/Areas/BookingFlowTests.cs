using System.Net;
using System.Text.Json;
using PAO.Core.Areas.Booking.Services.Shared;
using PAO.Lib.Areas.Booking;
using PAO.Lib.Areas.Catalog;
using PAO.TestKit;
using static PAO.IntegrationTests.Areas.BookingWorld;

namespace PAO.IntegrationTests.Areas;

public sealed class BookingFlowTests : IAsyncLifetime
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

    /// <summary>Searches, books and has the provider accept; checks privacy on the way.</summary>
    private static async Task<Guid> BookAndAccept(BookingWorld w)
    {
        var near = await w.AsCustomer(HttpMethod.Get, $"/v1/customer/providers/nearby?serviceId={Electrician}&subServiceId={Fan}&quantity=2&addressId={w.AddressId}");
        Assert.Equal(HttpStatusCode.OK, near.Status);
        Assert.Equal(1, near.Body.GetProperty("items").GetArrayLength());
        Assert.Equal("verified", near.Body.GetProperty("items")[0].GetProperty("badge").GetString());
        Assert.Equal(100000, near.Body.GetProperty("priceSummary").GetProperty("total").GetInt64());
        var id = await w.Book("booking-key-1");
        var before = (await w.AsProvider(HttpMethod.Get, $"/v1/provider/jobs/{id}")).Body;
        Assert.False(before.GetProperty("address").TryGetProperty("line1", out _));
        Assert.False(before.GetProperty("customer").TryGetProperty("phone", out _));
        Assert.Equal("BOOKING_INVALID_TRANSITION", Code(await w.AsCustomer(HttpMethod.Get, $"/v1/customer/bookings/{id}/start-code")));
        var accepted = (await w.Job(id, "accept")).Body;
        Assert.Equal("accepted", accepted.GetProperty("status").GetString());
        Assert.Equal("House 12, Road 5", accepted.GetProperty("address").GetProperty("line1").GetString());
        Assert.True(accepted.GetProperty("customer").TryGetProperty("phone", out _));
        return id;
    }

    /// <summary>Starts the job and has the customer approve one extra item.</summary>
    private static async Task StartWithExtras(BookingWorld w, Guid id)
    {
        var code = await w.Code(id);
        await w.Job(id, "on-the-way");
        await w.Job(id, "arrived");
        Assert.Equal("START_CODE_INVALID", Code(await w.Job(id, "start", new { code = code == "0000" ? "1111" : "0000" })));
        Assert.Equal("in_progress", (await w.Job(id, "start", new { code })).Body.GetProperty("status").GetString());
        var pending = (await w.Job(id, "extras", new { items = new[] { new { subServiceId = Socket, quantity = 1 } } })).Body.GetProperty("pendingExtras");
        Assert.Equal((35000, 135000), (pending.GetProperty("addedTotal").GetInt64(), pending.GetProperty("newTotal").GetInt64()));
        Assert.Equal("EXTRAS_PENDING", Code(await w.Job(id, "complete", new { cashReceived = true })));
        var decision = new { proposalId = pending.GetProperty("id").GetString(), approve = true };
        Assert.Equal(135000, (await w.AsCustomer(HttpMethod.Post, $"/v1/customer/bookings/{id}/extras/decision", decision)).Body.GetProperty("total").GetInt64());
        Assert.Equal("CASH_CONFIRMATION_REQUIRED", Code(await w.Job(id, "complete", new { cashReceived = false })));
    }

    [Fact]
    public async Task Runs_a_job_with_extras_to_the_receipt()
    {
        var w = await Create(api);
        var id = await BookAndAccept(w);
        await StartWithExtras(w, id);
        var done = (await w.Job(id, "complete", new { cashReceived = true })).Body;
        Assert.Equal(("completed", 2, 6), (done.GetProperty("status").GetString(), done.GetProperty("items").GetArrayLength(), done.GetProperty("timeline").GetArrayLength()));
        var receipt = (await w.AsCustomer(HttpMethod.Get, $"/v1/customer/bookings/{id}/receipt")).Body;
        Assert.Equal((135000, "Rahim Uddin"), (receipt.GetProperty("total").GetInt64(), receipt.GetProperty("providerName").GetString()));
        Assert.Equal(HttpStatusCode.OK, (await w.AsProvider(HttpMethod.Get, $"/v1/provider/jobs/{id}/receipt")).Status);
        Assert.False((await w.AsCustomer(HttpMethod.Get, $"/v1/customer/bookings/{id}")).Body.GetProperty("reviewedByMe").GetBoolean());
        var sum = (await w.AsProvider(HttpMethod.Get, "/v1/provider/earnings/summary?period=week")).Body;
        Assert.Equal((135000, 1, 7), (sum.GetProperty("total").GetInt64(), sum.GetProperty("jobs").GetInt32(), sum.GetProperty("buckets").GetArrayLength()));
        Assert.Equal(1, (await w.AsProvider(HttpMethod.Get, "/v1/provider/earnings/jobs")).Body.GetProperty("items").GetArrayLength());
        Assert.Equal(1, (await w.AsCustomer(HttpMethod.Get, "/v1/customer/bookings?tab=past")).Body.GetProperty("items").GetArrayLength());
        await w.Relay();
        Assert.Equal(1, (await w.Contract<IBookingSharedService, MerchantStats>(b => b.GetMerchantStats(w.Provider.Id, CancellationToken.None))).CompletedJobs);
    }

    [Fact]
    public async Task Refuses_bad_requests()
    {
        var w = await Create(api, "01712345611", "01812345611");
        var past = api.Clock.Now.AddHours(-1).ToString("O");
        var cases = new (Dictionary<string, object?> Extra, string Code)[]
        {
            (new() { ["timing"] = "scheduled" }, "VALIDATION_FAILED"),
            (new() { ["timing"] = "scheduled", ["scheduledAt"] = past }, "VALIDATION_FAILED"),
            (new() { ["items"] = new[] { new { subServiceId = Tap, quantity = 1 } } }, "VALIDATION_FAILED"),
            (new() { ["items"] = new[] { new { subServiceId = Fan, quantity = 11 } } }, "VALIDATION_FAILED"),
            (new() { ["items"] = new[] { new { subServiceId = Guid.NewGuid(), quantity = 1 } } }, "VALIDATION_FAILED"),
            (new() { ["serviceId"] = Guid.NewGuid() }, "NOT_FOUND"),
            (new() { ["addressId"] = Guid.NewGuid() }, "VALIDATION_FAILED"),
            (new() { ["providerId"] = Guid.NewGuid() }, "PROVIDER_UNAVAILABLE"),
        };
        for (var i = 0; i < cases.Length; i++)
        {
            Assert.Equal(cases[i].Code, Code(await w.Request($"rules-{i}", cases[i].Extra)));
        }
        var stranger = api.Api.Token(Guid.NewGuid(), "customer");
        Assert.Equal("PROFILE_REQUIRED", Code(await w.Request("rules-x", null, stranger)));
    }

    [Fact]
    public async Task Keeps_bookings_and_searches_inside_the_launch_area()
    {
        var w = await Create(api, "01712345621", "01812345621");
        await api.SetSetting("service_area.geojson", """{"type":"Polygon","coordinates":[[[91,22],[92,22],[92,23],[91,22]]]}""");
        Assert.Equal("OUTSIDE_SERVICE_AREA", Code(await w.Request("area")));
        var point = $"/v1/customer/providers/nearby?serviceId={Electrician}&subServiceId={Fan}&quantity=1&lat=23.79&lng=90.40";
        Assert.Equal("OUTSIDE_SERVICE_AREA", Code(await w.AsCustomer(HttpMethod.Get, point)));
        await api.SetSetting("service_area.geojson", string.Empty);
        Assert.Equal(1, (await w.AsCustomer(HttpMethod.Get, $"{point}&sort=rating")).Body.GetProperty("items").GetArrayLength());
        Assert.Equal(HttpStatusCode.UnprocessableEntity, (await w.AsCustomer(HttpMethod.Get, $"/v1/customer/providers/nearby?serviceId={Electrician}&subServiceId={Fan}&quantity=1")).Status);
        Assert.Equal(HttpStatusCode.NotFound, (await w.AsCustomer(HttpMethod.Get, $"/v1/customer/bookings/{Guid.NewGuid()}")).Status);
    }

    [Fact]
    public async Task Locks_the_start_code_and_books_duration_hires()
    {
        var w = await Create(api, "01712345631", "01812345631");
        var id = await w.Book("lockout");
        await w.Job(id, "accept");
        var code = await w.Code(id);
        var wrong = code == "0000" ? "1111" : "0000";
        Assert.Equal("BOOKING_INVALID_TRANSITION", Code(await w.Job(id, "start", new { code })));
        await w.Job(id, "on-the-way");
        await w.Job(id, "arrived");
        for (var i = 0; i < 5; i++)
        {
            await w.Job(id, "start", new { code = wrong });
        }
        Assert.Equal("START_CODE_LOCKED", Code(await w.Job(id, "start", new { code })));
        api.Clock.Advance(TimeSpan.FromMinutes(10));
        await w.RefreshTokens("01712345631", "01812345631");
        Assert.Equal("in_progress", (await w.Job(id, "start", new { code })).Body.GetProperty("status").GetString());
        Assert.Equal("VALIDATION_FAILED", Code(await w.Job(id, "extras", new { items = new[] { new { subServiceId = Tap, quantity = 1 } } })));
        var path = $"/v1/customer/bookings/{id}";
        Assert.Equal("NO_PENDING_EXTRAS", Code(await w.AsCustomer(HttpMethod.Post, $"{path}/extras/decision", new { proposalId = Guid.NewGuid(), approve = true })));
        Assert.Equal("BOOKING_INVALID_TRANSITION", Code(await w.AsCustomer(HttpMethod.Get, $"{path}/receipt")));
        var driver = SeedIds.For("service", "driver");
        var hire = new Dictionary<string, object?> { ["serviceId"] = driver, ["items"] = new[] { new { subServiceId = SeedIds.For("sub-service", "driver-day"), quantity = 1 } } };
        Assert.Equal("PROVIDER_UNAVAILABLE", Code(await w.Request("driver-1", hire)));
        var pro = await VerifiedProvider(api, "01712345699", driver);
        var booked = await w.Request("driver-2", new Dictionary<string, object?>(hire) { ["providerId"] = pro.Id });
        Assert.Equal(HttpStatusCode.Created, booked.Status);
        var span = DateTimeOffset.Parse(booked.Body.GetProperty("endsAt").GetString()!) - DateTimeOffset.Parse(booked.Body.GetProperty("createdAt").GetString()!);
        Assert.Equal(TimeSpan.FromDays(1), span);
    }
}
