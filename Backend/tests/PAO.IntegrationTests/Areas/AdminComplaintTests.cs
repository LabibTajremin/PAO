using System.Net;
using System.Text.Json;
using Microsoft.Extensions.DependencyInjection;
using PAO.Core.Areas.Admin.Services.Shared;
using PAO.TestKit;
using static PAO.IntegrationTests.Areas.BookingWorld;

namespace PAO.IntegrationTests.Areas;

/// <summary>Settings, reports filed on real bookings and the support queue.</summary>
public sealed class AdminComplaintTests : IAsyncLifetime
{
    private const string Radius = "/v1/admin/settings/search.default_radius_m";
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
    public async Task Applies_settings_at_once_refuses_bad_ones_and_falls_back_to_defaults()
    {
        var root = Guid.NewGuid();
        var token = api.Api.Token(root, "super_admin");
        var s = await Admin(a => a.GetSettings(CancellationToken.None));
        Assert.Equal((5000, 180_000L, 3.5, 365L * 86_400_000), (s.DefaultSearchRadiusM, s.AcceptTimeoutAsapMs, s.RatingFloor, s.DocumentRetentionMs));
        var r = await api.Call(HttpMethod.Put, Radius, token, new { value = "7000" });
        Assert.Equal((HttpStatusCode.OK, "7000", root.ToString()), (r.Status, r.Body.GetProperty("value").GetString(), r.Body.GetProperty("updatedBy").GetString()));
        Assert.Equal(7000, (await Admin(a => a.GetSettings(CancellationToken.None))).DefaultSearchRadiusM);
        Assert.Equal(14, (await api.Call(HttpMethod.Get, "/v1/admin/settings", token)).Body.GetProperty("items").GetArrayLength());
        Assert.Equal("SETTING_INVALID", Code(await api.Call(HttpMethod.Put, Radius, token, new { value = "far" })));
        Assert.Equal("SETTING_INVALID", Code(await api.Call(HttpMethod.Put, "/v1/admin/settings/billing.commission_rate_bp", token, new { value = "10001" })));
        Assert.Equal("SETTING_INVALID", Code(await api.Call(HttpMethod.Put, "/v1/admin/settings/billing.due_block_amount", token, new { value = "-1" })));
        Assert.Equal(HttpStatusCode.OK, (await api.Call(HttpMethod.Put, "/v1/admin/settings/billing.commission_rate_bp", token, new { value = "10000" })).Status);
        Assert.Equal(HttpStatusCode.NotFound, (await api.Call(HttpMethod.Put, "/v1/admin/settings/no.such_key", token, new { value = "1" })).Status);
        var catalog = api.Api.Token("catalog_manager");
        Assert.Equal(HttpStatusCode.OK, (await api.Call(HttpMethod.Get, "/v1/admin/settings", catalog)).Status);
        Assert.Equal(HttpStatusCode.Forbidden, (await api.Call(HttpMethod.Put, Radius, catalog, new { value = "1" })).Status);
        Assert.Equal(0, await Admin(a => a.CountVerifiedComplaints(Guid.NewGuid(), CancellationToken.None)));
        await api.Sql("UPDATE admin.settings SET value = 'x' WHERE type IN ('integer', 'number')");
        await api.ForgetSettings();
        var damaged = await Admin(a => a.GetSettings(CancellationToken.None));
        Assert.Equal((3.5, 5), (damaged.RatingFloor, damaged.StartCodeMaxAttempts));
        await api.SettingsDown(true);
        Assert.Equal(HttpStatusCode.InternalServerError, (await api.Call(HttpMethod.Get, "/v1/admin/settings", token)).Status);
        await Assert.ThrowsAnyAsync<Exception>(() => Admin(a => a.GetSettings(CancellationToken.None)));
        await api.SettingsDown(false);
    }

    [Fact]
    public async Task Takes_reports_from_both_sides_and_works_the_queue()
    {
        var w = await Create(api, "01712345661", "01812345661");
        var id = await w.Book("report-1");
        var photo = await api.Avatar(w.Customer.Token, "customer", "complaint_photo");
        var late = new { reason = "late", description = "Arrived two hours late.", photoMediaIds = new[] { photo } };
        var mine = await w.AsCustomer(HttpMethod.Post, $"/v1/customer/bookings/{id}/reports", late);
        Assert.Equal(HttpStatusCode.Created, mine.Status);
        Assert.Equal((w.Provider.Id.ToString(), "open"), (mine.Body.GetProperty("againstId").GetString(), mine.Body.GetProperty("status").GetString()));
        Assert.Matches("^TCK-\\d{6}$", mine.Body.GetProperty("ticketNumber").GetString());
        var theirs = await w.AsProvider(HttpMethod.Post, $"/v1/provider/jobs/{id}/reports", new { reason = "customer_unavailable", description = "Nobody answered the door." });
        Assert.Equal((w.Customer.Id.ToString(), "provider"), (theirs.Body.GetProperty("againstId").GetString(), theirs.Body.GetProperty("reporterRole").GetString()));
        await Refusals(w, id, late);
        var agent = Guid.NewGuid();
        await api.Sql($"INSERT INTO identity.accounts (id, phone, email, status, created_at, updated_at) VALUES ('{agent}', NULL, 'agent@pao.bd', 'active', now(), now())");
        await api.Sql($"INSERT INTO identity.account_roles (account_id, role) VALUES ('{agent}', 'support_agent')");
        var auth = api.Api.Token(agent, "support_agent");
        var complaintId = mine.Body.GetProperty("id").GetString();
        var resolved = await Resolve(auth, agent, complaintId!);
        Assert.Equal(1, resolved.GetProperty("comments").GetArrayLength());
        await w.Relay();
        Assert.Equal(1, await Admin(a => a.CountVerifiedComplaints(w.Provider.Id, CancellationToken.None)));
        var queue = (await api.Call(HttpMethod.Get, "/v1/admin/complaints?status=open&limit=1", auth)).Body;
        Assert.Equal(1, queue.GetProperty("items").GetArrayLength());
        Assert.False(queue.TryGetProperty("nextCursor", out _));
        Assert.Equal(1, (await api.Call(HttpMethod.Get, $"/v1/admin/complaints?assigneeId={agent}", auth)).Body.GetProperty("items").GetArrayLength());
        var two = (await api.Call(HttpMethod.Get, "/v1/admin/complaints?limit=1", auth)).Body;
        Assert.Equal(1, (await api.Call(HttpMethod.Get, $"/v1/admin/complaints?limit=1&cursor={two.GetProperty("nextCursor").GetString()}", auth)).Body.GetProperty("items").GetArrayLength());
        Assert.Equal(HttpStatusCode.UnprocessableEntity, (await api.Call(HttpMethod.Get, "/v1/admin/complaints?cursor=%25", auth)).Status);
        foreach (var (action, body) in new (string, object)[] { ("assign", new { assigneeId = agent }), ("comments", new { body = "x" }), ("resolve", new { resolution = "Done here.", verified = false }) })
        {
            Assert.Equal(HttpStatusCode.NotFound, (await api.Call(HttpMethod.Post, $"/v1/admin/complaints/{Guid.NewGuid()}/{action}", auth, body)).Status);
        }
        Assert.Equal(HttpStatusCode.NotFound, (await api.Call(HttpMethod.Get, $"/v1/admin/complaints/{Guid.NewGuid()}", auth)).Status);
    }

    private async Task<JsonElement> Resolve(string auth, Guid agent, string id)
    {
        var path = $"/v1/admin/complaints/{id}";
        Assert.Equal(HttpStatusCode.UnprocessableEntity, (await api.Call(HttpMethod.Post, $"{path}/assign", auth, new { assigneeId = Guid.NewGuid() })).Status);
        Assert.Equal(agent.ToString(), (await api.Call(HttpMethod.Post, $"{path}/assign", auth, new { assigneeId = agent })).Body.GetProperty("assigneeId").GetString());
        Assert.Equal("assigned", (await api.Call(HttpMethod.Get, path, auth)).Body.GetProperty("status").GetString());
        Assert.Equal(HttpStatusCode.Created, (await api.Call(HttpMethod.Post, $"{path}/comments", auth, new { body = "Called the provider." })).Status);
        Assert.Equal(HttpStatusCode.UnprocessableEntity, (await api.Call(HttpMethod.Post, $"{path}/resolve", auth, new { resolution = "  ok   ", verified = false })).Status);
        var r = (await api.Call(HttpMethod.Post, $"{path}/resolve", auth, new { resolution = "Provider warned; partial refund agreed.", verified = true })).Body;
        Assert.Equal(("resolved", true), (r.GetProperty("status").GetString(), r.GetProperty("verified").GetBoolean()));
        Assert.Equal("COMPLAINT_INVALID_TRANSITION", Code(await api.Call(HttpMethod.Post, $"{path}/resolve", auth, new { resolution = "Second attempt.", verified = false })));
        Assert.Equal(HttpStatusCode.Conflict, (await api.Call(HttpMethod.Post, $"{path}/assign", auth, new { assigneeId = agent })).Status);
        return r;
    }

    private async Task Refusals(BookingWorld w, Guid id, object late)
    {
        var (stranger, _) = await NewCustomer(api, "01812345662");
        var asCustomer = api.Api.Token(w.Provider.Id, "customer");
        var mine = $"/v1/customer/bookings/{id}/reports";
        var cases = new (string Path, object Body, string Token, string Code)[]
        {
            (mine, late, stranger.Token, "NOT_FOUND"),
            ($"/v1/customer/bookings/{Guid.NewGuid()}/reports", late, w.Customer.Token, "NOT_FOUND"),
            (mine, late, asCustomer, "NOT_FOUND"),
            (mine, new { reason = "late", description = "    late     " }, w.Customer.Token, "VALIDATION_FAILED"),
            ($"/v1/provider/jobs/{id}/reports", late, w.Provider.Token, "UPLOAD_INVALID"),
            (mine, new { reason = "late", description = "Arrived two hours late.", photoMediaIds = new[] { Guid.NewGuid() } }, w.Customer.Token, "UPLOAD_INVALID"),
        };
        foreach (var c in cases)
        {
            Assert.Equal(c.Code, Code(await api.Call(HttpMethod.Post, c.Path, c.Token, c.Body)));
        }
    }

    private async Task<T> Admin<T>(Func<IAdminSharedService, Task<T>> call)
    {
        using var scope = api.Services.CreateScope();
        return await call(scope.ServiceProvider.GetRequiredService<IAdminSharedService>());
    }
}
