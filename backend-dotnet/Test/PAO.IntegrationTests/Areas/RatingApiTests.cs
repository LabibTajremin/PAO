using System.Net;
using System.Text.Json;
using PAO.Core.Areas.Rating.Services.Shared;
using PAO.Lib.Areas.Rating;
using PAO.TestKit;
using static PAO.IntegrationTests.Areas.BookingWorld;

namespace PAO.IntegrationTests.Areas;

public sealed class RatingApiTests : IAsyncLifetime
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
    public async Task Takes_one_review_per_side_after_completion_and_shows_who_reviewed()
    {
        var w = await Create(api);
        var open = await w.Book("rating-open");
        Assert.Equal("REVIEW_NOT_ALLOWED", Code(await w.AsCustomer(HttpMethod.Post, $"/v1/customer/bookings/{open}/review", new { stars = 5 })));
        Assert.False((await w.AsCustomer(HttpMethod.Get, $"/v1/customer/bookings/{open}")).Body.GetProperty("reviewedByMe").GetBoolean());
        await w.AsCustomer(HttpMethod.Post, $"/v1/customer/bookings/{open}/cancel", new { reason = "other" });
        var id = await w.Completed("rating-done");
        await w.Relay();
        var path = $"/v1/customer/bookings/{id}/review";
        Assert.False((await w.AsCustomer(HttpMethod.Get, $"/v1/customer/bookings/{id}")).Body.GetProperty("reviewedByMe").GetBoolean());
        var first = await w.AsCustomer(HttpMethod.Post, path, new { stars = 4, tags = new[] { "on_time", "clean" }, comment = " Quick and tidy " });
        Assert.Equal(HttpStatusCode.Created, first.Status);
        Assert.Equal(("Nusrat", "Quick and tidy"), (first.Body.GetProperty("authorName").GetString(), first.Body.GetProperty("comment").GetString()));
        Assert.True((await w.AsCustomer(HttpMethod.Get, $"/v1/customer/bookings/{id}")).Body.GetProperty("reviewedByMe").GetBoolean());
        Assert.Equal("REVIEW_ALREADY_SUBMITTED", Code(await w.AsCustomer(HttpMethod.Post, path, new { stars = 4 })));
        Assert.Equal("VALIDATION_FAILED", Code(await w.AsProvider(HttpMethod.Post, $"/v1/provider/jobs/{id}/review", new { stars = 5, comment = new string('x', 450) + new string('য', 60) })));
        var second = await w.AsProvider(HttpMethod.Post, $"/v1/provider/jobs/{id}/review", new { stars = 5, tags = new[] { "polite", "paid_promptly" } });
        Assert.Equal(HttpStatusCode.Created, second.Status);
        Assert.False(second.Body.TryGetProperty("comment", out _));
        Assert.Equal("REVIEW_NOT_ALLOWED", Code(await w.AsCustomer(HttpMethod.Post, $"/v1/provider/jobs/{id}/review", new { stars = 5 })));
        await w.Relay();
        var mine = (await w.AsProvider(HttpMethod.Get, "/v1/provider/rating")).Body;
        Assert.Equal((4.0, 1, 1), (mine.GetProperty("average").GetDouble(), mine.GetProperty("count").GetInt32(), mine.GetProperty("distribution").GetProperty("4").GetInt32()));
        Assert.Equal(1, (await w.AsProvider(HttpMethod.Get, "/v1/provider/reviews")).Body.GetProperty("items").GetArrayLength());
        var pub = (await w.AsCustomer(HttpMethod.Get, $"/v1/customer/providers/{w.Provider.Id}")).Body;
        Assert.Equal((1, 1), (pub.GetProperty("completedJobs").GetInt32(), pub.GetProperty("rating").GetProperty("count").GetInt32()));
        var customer = await w.Contract<IRatingSharedService, RatingSummary>(r => r.GetCustomerRating(w.Customer.Id, CancellationToken.None));
        Assert.Equal((5.0, 1), (customer.Average, customer.Count));
        var all = await w.Contract<IRatingSharedService, IReadOnlyDictionary<Guid, RatingSummary>>(r => r.GetMerchantRatings([w.Provider.Id, Guid.NewGuid()], CancellationToken.None));
        Assert.Equal([w.Provider.Id], all.Keys);
        Assert.Equal(0, (await w.Contract<IRatingSharedService, RatingSummary>(r => r.GetMerchantRating(Guid.NewGuid(), CancellationToken.None))).Count);
        Assert.True(await w.Contract<IRatingSharedService, bool>(r => r.HasReviewed(id, w.Customer.Id, CancellationToken.None)));
        Assert.True((await w.AsProvider(HttpMethod.Get, $"/v1/provider/jobs/{id}")).Body.GetProperty("reviewedByMe").GetBoolean());
    }

    [Fact]
    public async Task Opens_once_pages_reviews_erases_authors_and_fails_without_the_database()
    {
        var w = await Create(api, "01712345621", "01812345621");
        var first = await w.Completed("rating-p1");
        await w.Relay();
        await api.Deliver("booking.BookingCompleted", new { bookingId = first, customerName = "Someone Else" }, api.Bus(true));
        await api.Deliver("booking.BookingCompleted", new { bookingId = Guid.NewGuid(), at = "2026-10-01T00:00:00Z", serviceName = new { en = "Fan", bn = "ফ্যান" } }, api.Bus(true));
        var (other, address) = await NewCustomer(api, "01812345622");
        await w.AsCustomer(HttpMethod.Post, $"/v1/customer/bookings/{first}/review", new { stars = 5 });
        var r = await w.Request("rating-p2", new() { ["addressId"] = address }, other.Token);
        var second = Guid.Parse(r.Body.GetProperty("id").GetString()!);
        await w.Job(second, "accept");
        var code = (await api.Call(HttpMethod.Get, $"/v1/customer/bookings/{second}/start-code", other.Token)).Body.GetProperty("code").GetString();
        await w.Job(second, "on-the-way");
        await w.Job(second, "arrived");
        await w.Job(second, "start", new { code });
        Assert.Equal(HttpStatusCode.OK, (await w.Job(second, "complete", new { cashReceived = true })).Status);
        await w.Relay();
        Assert.Equal(HttpStatusCode.Created, (await api.Call(HttpMethod.Post, $"/v1/customer/bookings/{second}/review", other.Token, new { stars = 4, comment = "Fine" })).Status);
        var list = $"/v1/customer/providers/{w.Provider.Id}/reviews?limit=1";
        var page = (await api.Call(HttpMethod.Get, list, other.Token)).Body;
        Assert.Equal(1, page.GetProperty("items").GetArrayLength());
        var next = (await api.Call(HttpMethod.Get, $"{list}&cursor={page.GetProperty("nextCursor").GetString()}", other.Token)).Body;
        Assert.Equal(1, next.GetProperty("items").GetArrayLength());
        Assert.False(next.TryGetProperty("nextCursor", out _));
        Assert.Equal(HttpStatusCode.UnprocessableEntity, (await api.Call(HttpMethod.Get, $"{list}&cursor=%25", other.Token)).Status);
        await api.Deliver("identity.AccountDeleted", new { accountId = other.Id }, api.Bus(true));
        var erased = (await w.AsProvider(HttpMethod.Get, "/v1/provider/reviews")).Body.GetProperty("items")[0];
        Assert.Equal(string.Empty, erased.GetProperty("authorName").GetString());
        await api.Sql("ALTER TABLE rating.aggregates RENAME TO aggregates_gone");
        Assert.Equal(HttpStatusCode.InternalServerError, (await w.AsProvider(HttpMethod.Post, $"/v1/provider/jobs/{first}/review", new { stars = 3 })).Status);
        Assert.Equal(HttpStatusCode.InternalServerError, (await w.AsProvider(HttpMethod.Get, "/v1/provider/rating")).Status);
        await api.Sql("ALTER TABLE rating.aggregates_gone RENAME TO aggregates");
        await api.Sql("ALTER TABLE rating.reviews RENAME TO reviews_gone");
        Assert.Equal(HttpStatusCode.InternalServerError, (await w.AsCustomer(HttpMethod.Get, $"/v1/customer/bookings/{first}")).Status);
        await api.Sql("ALTER TABLE rating.reviews_gone RENAME TO reviews");
    }
}
