using System.Net;
using System.Text.Json;
using Microsoft.Extensions.DependencyInjection;
using PAO.BackgroundJobs;
using PAO.Core.Areas.Booking.Features.Progress.Commands;
using PAO.Core.Areas.Booking.Features.Requests.Commands;
using PAO.Core.Areas.Booking.Features.Respond.Commands;
using PAO.Core.Areas.Booking.Services;
using PAO.Core.Areas.Booking.Services.Shared;
using PAO.Lib.Areas.Booking;
using PAO.Lib.Errors;
using PAO.TestKit;
using static PAO.IntegrationTests.Areas.BookingWorld;

namespace PAO.IntegrationTests.Areas;

public sealed class BookingExitTests : IAsyncLifetime
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

    private static string? Status((HttpStatusCode, JsonElement Body) r) => r.Body.GetProperty("status").GetString();

    [Fact]
    public async Task Rejects_times_out_and_cancels()
    {
        var w = await Create(api);
        var rejected = await w.Book("reject");
        Assert.Equal("rejected", Status(await w.Job(rejected, "reject", new { reason = "busy", note = "Another job" })));
        var timedOut = await w.Book("timeout");
        api.Clock.Advance(TimeSpan.FromMinutes(3));
        var job = new BookingExpiryJob(api.Services.GetRequiredService<IServiceScopeFactory>());
        Assert.Equal(("booking.expire_requests", TimeSpan.FromSeconds(15)), (job.Name, job.Schedule.DelayFrom(api.Clock.Now)));
        await job.Run(CancellationToken.None);
        await w.RefreshTokens();
        Assert.Equal("timed_out", Status(await w.AsCustomer(HttpMethod.Get, $"/v1/customer/bookings/{timedOut}")));
        Assert.Equal("BOOKING_INVALID_TRANSITION", Code(await w.Job(timedOut, "accept")));
        var free = await w.Book("cancel-free");
        Assert.Equal("cancelled", Status(await w.AsCustomer(HttpMethod.Post, $"/v1/customer/bookings/{free}/cancel", new { reason = "changed_mind" })));
        Assert.Equal("BOOKING_INVALID_TRANSITION", Code(await w.Job(free, "cancel", new { reason = "emergency" })));
        var byProvider = await w.Book("cancel-provider");
        await w.Job(byProvider, "accept");
        Assert.Equal("cancelled", Status(await w.Job(byProvider, "cancel", new { reason = "emergency" })));
        var started = await w.Book("started");
        await w.Run(started);
        Assert.Equal("CANCELLATION_NOT_ALLOWED", Code(await w.AsCustomer(HttpMethod.Post, $"/v1/customer/bookings/{started}/cancel", new { reason = "changed_mind" })));
        await w.Relay();
        var stats = await w.Contract<IBookingSharedService, MerchantStats>(b => b.GetMerchantStats(w.Provider.Id, CancellationToken.None));
        Assert.Equal(1, stats.Cancellations30d);
        Assert.Equal(1, await w.Contract<IBookingSharedService, int>(b => b.CountActiveJobs(w.Provider.Id, CancellationToken.None)));
        Assert.Equal(1, (await w.AsProvider(HttpMethod.Get, "/v1/provider/jobs?tab=upcoming")).Body.GetProperty("items").GetArrayLength());
        var past = (await w.AsProvider(HttpMethod.Get, "/v1/provider/jobs?tab=past&limit=2")).Body;
        Assert.Equal(2, past.GetProperty("items").GetArrayLength());
        var more = await w.AsProvider(HttpMethod.Get, $"/v1/provider/jobs?tab=past&limit=2&cursor={past.GetProperty("nextCursor").GetString()}");
        Assert.Equal(2, more.Body.GetProperty("items").GetArrayLength());
        Assert.Equal(0, await w.Send(new ExpireDueRequests()));
    }

    [Fact]
    public async Task Replays_a_key_and_lets_one_accept_win()
    {
        var w = await Create(api, "01712345612", "01812345612");
        var first = await w.Book("same-key");
        Assert.Equal(first, await w.Book("same-key"));
        Assert.Equal("DUPLICATE_BOOKING_REQUEST", Code(await w.Request("other-key")));
        var answers = await Task.WhenAll(Enumerable.Range(0, 5).Select(_ => w.Job(first, "accept")));
        Assert.Single(answers, a => a.Status == HttpStatusCode.OK);
        var asap = await w.Book("second-asap");
        Assert.Equal("ACTIVE_JOB_EXISTS", Code(await w.Job(asap, "accept")));
        await w.Job(asap, "reject", new { reason = "busy" });
        var when = api.Clock.Now.AddDays(1).ToString("O");
        var scheduled = await w.Book("scheduled", new() { ["timing"] = "scheduled", ["scheduledAt"] = when });
        Assert.Equal("accepted", Status(await w.Job(scheduled, "accept")));
        var late = await w.Book("late");
        api.Clock.Advance(TimeSpan.FromMinutes(4));
        await w.RefreshTokens("01712345612", "01812345612");
        Assert.Equal("ACCEPT_DEADLINE_PASSED", Code(await w.Job(late, "reject", new { reason = "busy" })));
    }

    [Fact]
    public async Task Keeps_each_side_to_its_own_endpoints()
    {
        var w = await Create(api, "01712345613", "01812345613");
        var both = api.Api.Token(w.Provider.Id, "provider", "customer");
        var id = await w.Book("edge-1");
        foreach (var path in new[] { $"/v1/customer/bookings/{id}", $"/v1/customer/bookings/{id}/start-code" })
        {
            Assert.Equal(HttpStatusCode.NotFound, (await api.Call(HttpMethod.Get, path, both)).Status);
        }
        Assert.Equal(HttpStatusCode.NotFound, (await api.Call(HttpMethod.Post, $"/v1/customer/bookings/{id}/cancel", both, new { reason = "other" })).Status);
        Assert.Equal(HttpStatusCode.NotFound, (await w.Job(Guid.NewGuid(), "accept")).Status);
        await w.Job(id, "reject", new { reason = "busy" });
        Assert.Equal("BOOKING_INVALID_TRANSITION", Code(await w.Job(id, "reject", new { reason = "busy" })));
        var custView = api.Api.Token(w.Customer.Id, "customer", "provider");
        var second = await w.Book("edge-2");
        Assert.Equal(HttpStatusCode.NotFound, (await api.Call(HttpMethod.Post, $"/v1/provider/jobs/{second}/accept", custView)).Status);
        await w.Run(second);
        Assert.Equal("BOOKING_INVALID_TRANSITION", Code(await w.Job(second, "on-the-way")));
        var extras = new { items = new[] { new { subServiceId = Socket, quantity = 1 } } };
        var p1 = (await w.Job(second, "extras", extras)).Body.GetProperty("pendingExtras").GetProperty("id").GetString();
        var decide = $"/v1/customer/bookings/{second}/extras/decision";
        Assert.Equal(HttpStatusCode.NotFound, (await api.Call(HttpMethod.Post, decide, both, new { proposalId = p1, approve = true })).Status);
        await w.AsCustomer(HttpMethod.Post, decide, new { proposalId = p1, approve = false });
        var again = (await w.Job(second, "extras", extras)).Body.GetProperty("pendingExtras");
        Assert.True(again.GetProperty("items")[0].GetProperty("extra").GetBoolean());
        Assert.Equal("EXTRAS_PENDING", Code(await w.Job(second, "extras", extras)));
        await Assert.ThrowsAsync<DomainException>(() => w.Send(new ProposeExtras(w.Provider.Id, second, new ExtrasInput())));
        await Assert.ThrowsAsync<DomainException>(() => w.Send(new CreateBooking(w.Customer.Id, string.Empty, new BookingCreateInput())));
        var direct = new BookingCreateInput { ProviderId = w.Provider.Id, ServiceId = Electrician, AddressId = w.AddressId, Timing = "asap", Items = [new BookingItemInput { SubServiceId = Fan, Quantity = 1 }] };
        var made = await w.Send(new CreateBooking(w.Customer.Id, "direct-key-1", direct));
        Assert.Equal(made.Id, (await w.Send(new CreateBooking(w.Customer.Id, "direct-key-1", direct))).Id);
        await w.Send(new CancelBooking(Side.Customer, w.Customer.Id, made.Id, new ReasonInput { Reason = "other" }));
        await Assert.ThrowsAnyAsync<Exception>(() => w.Send(new AdvanceJob(w.Provider.Id, second, BookingStatus.Completed)));
        await Assert.ThrowsAnyAsync<Exception>(() => w.Send(new CancelBooking(Side.Any, w.Customer.Id, second, new ReasonInput { Reason = "other" })));
        var when = api.Clock.Now.AddHours(2).ToString("O");
        await w.Book("edge-scheduled", new() { ["timing"] = "scheduled", ["scheduledAt"] = when, ["items"] = new[] { new { subServiceId = Fan, quantity = 1 } } });
        Assert.True((await w.AsCustomer(HttpMethod.Get, "/v1/customer/bookings?tab=upcoming")).Body.GetProperty("items").GetArrayLength() >= 2);
    }
}
