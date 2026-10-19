using System.Net;
using System.Text.Json;
using Microsoft.Extensions.DependencyInjection;
using PAO.TestKit;
using static PAO.IntegrationTests.Areas.BookingWorld;

namespace PAO.IntegrationTests.Areas;

/// <summary>The provider and customer console and the dashboard.</summary>
public sealed class AdminPeopleTests : IAsyncLifetime
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

    private async Task<int> Count(string path, string token) => (await api.Call(HttpMethod.Get, path, token)).Body.GetProperty("items").GetArrayLength();

    private static JsonElement Summary((HttpStatusCode, JsonElement Body) r) => r.Body.GetProperty("summary");

    [Fact]
    public async Task Lists_shows_bans_and_reinstates_providers()
    {
        var w = await Create(api, "01712345681", "01812345681");
        await w.Completed("people-1");
        await w.Relay();
        var pending = await api.Enrol("01712345682", "female", Electrician);
        var support = api.Api.Token("support_agent");
        var root = api.Api.Token(Guid.NewGuid(), "super_admin");
        Assert.Equal(2, await Count("/v1/admin/providers", support));
        Assert.Equal(1, await Count("/v1/admin/providers?status=pending", support));
        Assert.Equal(1, await Count("/v1/admin/providers?status=active&level=1&flagged=false", support));
        Assert.Equal(1, await Count("/v1/admin/providers?q=12345681", support));
        var first = (await api.Call(HttpMethod.Get, "/v1/admin/providers?limit=1", support)).Body;
        Assert.Equal(1, await Count($"/v1/admin/providers?limit=1&cursor={first.GetProperty("nextCursor").GetString()}", support));
        var path = $"/v1/admin/providers/{w.Provider.Id}";
        var d = (await api.Call(HttpMethod.Get, path, support)).Body;
        Assert.Equal(("male", "active", 1, true), (d.GetProperty("gender").GetString(), d.GetProperty("summary").GetProperty("status").GetString(),
            d.GetProperty("summary").GetProperty("level").GetInt32(), d.GetProperty("summary").GetProperty("online").GetBoolean()));
        Assert.Equal(1, d.GetProperty("summary").GetProperty("services").GetArrayLength());
        Assert.Equal(1, d.GetProperty("recentBookings").GetArrayLength());
        var ban = new { status = "banned", reason = "Fraudulent documents" };
        Assert.Equal("banned", Summary(await api.Call(HttpMethod.Post, $"{path}/status", root, ban)).GetProperty("status").GetString());
        Assert.Equal("CONFLICT", PeopleApi.Code((await api.Call(HttpMethod.Post, $"{path}/status", root, ban)).Body));
        var back = new { status = "active", reason = "Appeal accepted" };
        Assert.Equal("active", Summary(await api.Call(HttpMethod.Post, $"{path}/status", root, back)).GetProperty("status").GetString());
        var pendingPath = $"/v1/admin/providers/{pending.Id}";
        Assert.Equal("suspended", Summary(await api.Call(HttpMethod.Post, $"{pendingPath}/status", root, new { status = "suspended", reason = "Checking" })).GetProperty("status").GetString());
        Assert.Equal("pending", Summary(await api.Call(HttpMethod.Post, $"{pendingPath}/status", root, new { status = "active", reason = "Checked" })).GetProperty("status").GetString());
        foreach (var p in new[] { $"/v1/admin/providers/{Guid.NewGuid()}", $"/v1/admin/providers/{w.Customer.Id}" })
        {
            Assert.Equal(HttpStatusCode.NotFound, (await api.Call(HttpMethod.Get, p, support)).Status);
            Assert.Equal(HttpStatusCode.NotFound, (await api.Call(HttpMethod.Post, $"{p}/status", root, ban)).Status);
        }
        Assert.Equal(HttpStatusCode.UnprocessableEntity, (await api.Call(HttpMethod.Get, "/v1/admin/providers?cursor=%25", support)).Status);
    }

    [Fact]
    public async Task Lists_shows_and_suspends_customers_and_counts_the_dashboard()
    {
        var w = await Create(api, "01712345683", "01812345683");
        var id = await w.Completed("people-2");
        await NewCustomer(api, "01812345684");
        await w.AsCustomer(HttpMethod.Post, $"/v1/customer/bookings/{id}/reports", new { reason = "late", description = "Arrived two hours late." });
        await w.Relay();
        var support = api.Api.Token("support_agent");
        var root = api.Api.Token(Guid.NewGuid(), "super_admin");
        Assert.Equal(2, await Count("/v1/admin/customers", support));
        Assert.Equal(1, await Count("/v1/admin/customers?q=12345684", support));
        Assert.Equal(0, await Count("/v1/admin/customers?status=suspended", support));
        var first = (await api.Call(HttpMethod.Get, "/v1/admin/customers?limit=1", support)).Body;
        Assert.Equal(1, await Count($"/v1/admin/customers?limit=1&cursor={first.GetProperty("nextCursor").GetString()}", support));
        var path = $"/v1/admin/customers/{w.Customer.Id}";
        var d = (await api.Call(HttpMethod.Get, path, support)).Body;
        Assert.Equal((1, 1, 1), (d.GetProperty("summary").GetProperty("bookings").GetInt32(), d.GetProperty("recentBookings").GetArrayLength(), d.GetProperty("complaints").GetArrayLength()));
        Assert.False(d.GetProperty("summary").TryGetProperty("rating", out _));
        await w.AsProvider(HttpMethod.Post, $"/v1/provider/jobs/{id}/review", new { stars = 4 });
        var r = Summary(await api.Call(HttpMethod.Post, $"{path}/status", root, new { status = "suspended", reason = "Abusive messages" }));
        Assert.Equal(("suspended", 4.0), (r.GetProperty("status").GetString(), r.GetProperty("rating").GetDouble()));
        Assert.Equal(HttpStatusCode.Conflict, (await api.Call(HttpMethod.Post, $"{path}/status", root, new { status = "suspended", reason = "Again" })).Status);
        foreach (var p in new[] { $"/v1/admin/customers/{Guid.NewGuid()}", $"/v1/admin/customers/{w.Provider.Id}" })
        {
            Assert.Equal(HttpStatusCode.NotFound, (await api.Call(HttpMethod.Get, p, support)).Status);
            Assert.Equal(HttpStatusCode.NotFound, (await api.Call(HttpMethod.Post, $"{p}/status", root, new { status = "banned", reason = "Nope" })).Status);
        }
        await Dashboard(w, support);
    }

    private async Task Dashboard(BookingWorld w, string support)
    {
        var (other, address) = await NewCustomer(api, "01812345686");
        Assert.Equal(HttpStatusCode.Created, (await w.Request("people-open", new() { ["addressId"] = address }, other.Token)).Status);
        await api.Enrol("01712345685", "female", Electrician);
        await w.Relay();
        var bus = api.Bus(true);
        await Assert.ThrowsAnyAsync<Exception>(() => api.Deliver("identity.AccountCreated", new { role = "provider" }, bus));
        await api.Deliver("identity.AccountStatusChanged", new { accountId = Guid.NewGuid(), to = "banned", roles = new[] { "customer" } }, bus);
        var d = (await api.Call(HttpMethod.Get, "/v1/admin/dashboard", support)).Body;
        Assert.Equal(30, d.GetProperty("bookingsPerDay").GetArrayLength());
        var today = d.GetProperty("bookingsPerDay")[29];
        Assert.Equal((2, 1), (today.GetProperty("total").GetInt32(), today.GetProperty("completed").GetInt32()));
        Assert.Equal((0.5, 1), (d.GetProperty("completionRate").GetDouble(), d.GetProperty("openComplaints").GetInt32()));
        // The test verified the electrician through Merchant alone, so the dashboard still counts them pending.
        Assert.Equal(2, d.GetProperty("providersByStatus").GetProperty("pending").GetInt32());
        await api.Sql("ALTER TABLE admin.stats_providers RENAME TO stats_gone");
        Assert.Equal(HttpStatusCode.OK, (await api.Call(HttpMethod.Get, "/v1/admin/dashboard", support)).Status);
        await api.Services.GetRequiredService<PAO.Infrastructure.Redis.JsonCache>().Delete(api.Services.GetRequiredService<PAO.Infrastructure.Redis.RedisKeys>().Key("cache", "dashboard"));
        Assert.Equal(HttpStatusCode.InternalServerError, (await api.Call(HttpMethod.Get, "/v1/admin/dashboard", support)).Status);
        await api.Sql("ALTER TABLE admin.stats_gone RENAME TO stats_providers");
    }
}
