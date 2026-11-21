using System.Net;
using System.Text.Json.Nodes;
using Microsoft.Extensions.DependencyInjection;
using Microsoft.Extensions.Logging.Abstractions;
using Npgsql;
using PAO.Core.Areas.Audit.Services;
using PAO.Core.Areas.Audit.Services.Shared;
using PAO.Core.Areas.Identity.Services.Shared;
using PAO.Infrastructure.Data;
using PAO.Infrastructure.Events;
using PAO.Infrastructure.Metrics;
using PAO.Infrastructure.Outbox;
using PAO.IntegrationTests.Identity;
using PAO.Lib.Areas.Audit;
using PAO.Lib.Areas.Identity;
using PAO.TestKit;

namespace PAO.IntegrationTests.Audit;

public sealed class AuditApiTests : IAsyncLifetime
{
    private string url = string.Empty;
    private IdentityHost api = null!;
    private string token = null!;

    public async ValueTask InitializeAsync()
    {
        url = await TestDatabases.CreateMigrated();
        api = await IdentityHost.Start(url);
        token = (await api.Admin(["super_admin"])).AccessToken;
    }

    public async ValueTask DisposeAsync()
    {
        await api.DisposeAsync();
        await TestDatabases.Drop(url);
    }

    private static AuditEntry Entry(string subjectId = "s") => new()
    {
        Id = Guid.Empty,
        At = default,
        ActorRole = string.Empty,
        Action = "system.note",
        SubjectType = "system",
        SubjectId = subjectId,
        Reason = string.Empty,
    };

    private async Task Relay()
    {
        var bus = new EventBus();
        api.App.Services.GetServices<IEventSubscriptions>().Single(s => s is AuditSubscriptions).Subscribe(bus);
        var relay = new OutboxRelay(api.App.Services.GetRequiredService<NpgsqlDataSource>(), bus, ["identity"], new SystemClock(), new PaoMetrics().Worker, NullLogger<OutboxRelay>.Instance);
        await relay.RunOnce(CancellationToken.None);
    }

    private async Task Execute(string sql)
    {
        await using var connection = await TestDatabases.Open(url);
        await TestDatabases.Execute(connection, sql);
    }

    [Fact]
    public async Task Turns_events_into_entries_once_even_when_they_are_redelivered()
    {
        var superId = Guid.NewGuid();
        var customer = await api.SignIn("01712345678", "customer");
        var id = Guid.Parse(customer.GetProperty("account").GetProperty("id").GetString()!);
        using var scope = api.App.Services.CreateScope();
        await scope.ServiceProvider.GetRequiredService<IIdentitySharedService>().SetAccountStatus(
            new SetAccountStatusInput { AccountId = id, Status = AccountStatus.Suspended, Reason = "abuse", ActorId = superId }, CancellationToken.None);
        await Relay();
        await Execute("UPDATE identity.outbox SET published_at = NULL");
        await Relay();
        var r = await api.Do(HttpMethod.Get, $"/v1/admin/audit?action=account.status_changed&subjectId={id}", token: token);
        Assert.Equal("abuse", r.Body.GetProperty("items").EnumerateArray().Single().GetProperty("reason").GetString());
        var history = await scope.ServiceProvider.GetRequiredService<IAuditSharedService>().ListForSubject("account", id.ToString(), 10, CancellationToken.None);
        Assert.Equal(superId, Assert.Single(history).ActorId);
    }

    [Fact]
    public async Task Pages_and_filters_stays_append_only_and_reports_a_lost_database()
    {
        var actor = Guid.NewGuid();
        var start = DateTimeOffset.Parse("2026-10-01T00:00:00Z", System.Globalization.CultureInfo.InvariantCulture);
        using (var scope = api.App.Services.CreateScope())
        {
            var audit = scope.ServiceProvider.GetRequiredService<IAuditSharedService>();
            for (var i = 0; i < 3; i++)
            {
                await audit.Record(Entry("p1") with
                {
                    At = start.AddHours(i),
                    ActorId = actor,
                    ActorRole = "verifier",
                    Action = "verification.item_approved",
                    SubjectType = "provider",
                    Before = new JsonObject { ["a"] = 1 },
                    After = new JsonObject { ["b"] = 2 },
                }, CancellationToken.None);
            }
        }
        var q = $"actorId={actor}&limit=2&from={Uri.EscapeDataString(start.ToString("O"))}&to={Uri.EscapeDataString(start.AddHours(5).ToString("O"))}";
        var first = await api.Do(HttpMethod.Get, $"/v1/admin/audit?{q}", token: token);
        Assert.Equal(2, first.Body.GetProperty("items").GetArrayLength());
        Assert.Equal(1, first.Body.GetProperty("items")[0].GetProperty("before").GetProperty("a").GetInt32());
        var second = await api.Do(HttpMethod.Get, $"/v1/admin/audit?{q}&cursor={first.Text("nextCursor")}", token: token);
        Assert.Equal(1, second.Body.GetProperty("items").GetArrayLength());
        Assert.False(second.Body.TryGetProperty("nextCursor", out _));
        Assert.Equal(HttpStatusCode.UnprocessableEntity, (await api.Do(HttpMethod.Get, "/v1/admin/audit?cursor=%25%25", token: token)).Status);
        foreach (var statement in new[] { "UPDATE audit.entries SET reason = 'x'", "DELETE FROM audit.entries", "TRUNCATE audit.entries" })
        {
            await Assert.ThrowsAsync<PostgresException>(() => Execute(statement));
        }
        await TestDatabases.Drop(url);
        Assert.Equal(HttpStatusCode.InternalServerError, (await api.Do(HttpMethod.Get, "/v1/admin/audit", token: token)).Status);
    }

    [Fact]
    public async Task Leaves_out_what_a_sparse_entry_does_not_have()
    {
        using (var scope = api.App.Services.CreateScope())
        {
            await scope.ServiceProvider.GetRequiredService<IAuditSharedService>().Record(Entry(), CancellationToken.None);
        }
        var item = (await api.Do(HttpMethod.Get, "/v1/admin/audit?subjectId=s", token: token)).Body.GetProperty("items")[0];
        Assert.False(item.TryGetProperty("before", out _));
        Assert.False(item.TryGetProperty("actorRole", out _));
        Assert.False(item.TryGetProperty("actorId", out _));
    }
}
