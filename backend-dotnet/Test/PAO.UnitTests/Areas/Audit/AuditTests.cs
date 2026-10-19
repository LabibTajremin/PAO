using System.Text.Json;
using Microsoft.Extensions.DependencyInjection;
using PAO.Core.Areas.Audit.Features.ListAuditEntries.Queries;
using PAO.Core.Areas.Audit.Repositories;
using PAO.Core.Areas.Audit.Services;
using PAO.Core.Areas.Audit.Services.Shared;
using PAO.Infrastructure.Data;
using PAO.Infrastructure.Events;
using PAO.Lib.Areas.Audit;
using PAO.Lib.Errors;
using PAO.Lib.Mapping;
using PAO.TestKit;

namespace PAO.UnitTests.Areas.Audit;

public sealed class MemoryEntries : IAuditRepository
{
    public List<(AuditEntry Entry, Guid? EventId)> Entries { get; } = [];

    public Task Append(AuditEntry entry, Guid? eventId, CancellationToken cancellationToken)
    {
        Entries.Add((entry, eventId));
        return Task.CompletedTask;
    }

    public Task<IReadOnlyList<AuditEntry>> List(AuditFilter filter, AuditPage page, CancellationToken cancellationToken) =>
        Task.FromResult<IReadOnlyList<AuditEntry>>([.. Entries.Select(e => e.Entry).Take(page.Limit)]);
}

public sealed class AuditTests
{
    private static readonly DateTimeOffset Now = DateTimeOffset.Parse("2026-10-09T10:00:00Z", System.Globalization.CultureInfo.InvariantCulture);

    private static AuditEntry Entry(string action = "x", string subjectType = "y", string subjectId = "z") => new()
    {
        Id = Guid.Empty,
        At = default,
        ActorRole = string.Empty,
        Action = action,
        SubjectType = subjectType,
        SubjectId = subjectId,
        Reason = string.Empty,
    };

    [Fact]
    public void Entries_need_an_action_and_a_subject()
    {
        Assert.True(AuditReasons.IsComplete("a", "provider", "1"));
        Assert.False(AuditReasons.IsComplete(" ", "provider", "1"));
    }

    [Fact]
    public async Task Fills_in_id_and_time_and_refuses_incomplete_entries()
    {
        var repo = new MemoryEntries();
        var log = new AuditLog(repo, new FakeClock(Now), new UuidV7Generator());
        await new AuditSharedService(log).Record(Entry(), CancellationToken.None);
        Assert.Equal((Now, (Guid?)null), (repo.Entries[0].Entry.At, repo.Entries[0].EventId));
        Assert.NotEqual(Guid.Empty, repo.Entries[0].Entry.Id);
        var error = await Assert.ThrowsAsync<DomainException>(() => log.Record(Entry(string.Empty, string.Empty, string.Empty), null, CancellationToken.None));
        Assert.Equal(AuditReasons.Invalid, error.Reason);
        Assert.Single(await new AuditSharedService(log).ListForSubject("y", "z", 10, CancellationToken.None));
    }

    private static Dictionary<string, object> Payloads(Guid actor) => new()
    {
        ["identity.AccountStatusChanged"] = new { accountId = Guid.NewGuid(), from = "active", to = "banned", reason = "x", actorId = actor },
        ["catalog.PriceChanged"] = new { subServiceId = Guid.NewGuid(), priceVersionId = Guid.NewGuid(), amountPaisa = 100, actorId = (Guid?)null },
        ["verification.DocumentApproved"] = new { providerId = Guid.NewGuid(), item = "nid", actorId = actor },
        ["verification.DocumentRejected"] = new { providerId = Guid.NewGuid(), item = "nid", reason = "blurred", actorId = actor },
        ["verification.ProviderLevelChanged"] = new { providerId = Guid.NewGuid(), from = 0, to = 1, reason = string.Empty },
        ["verification.Level2ResultRecorded"] = new { providerId = Guid.NewGuid(), sessionId = Guid.NewGuid(), result = "pass", actorId = actor },
        ["verification.DocumentExpired"] = new { providerId = Guid.NewGuid(), item = "police_clearance" },
        ["admin.SettingChanged"] = new { key = "search.default_radius_m", before = "5000", after = "6000", actorId = actor },
        ["admin.ComplaintResolved"] = new { complaintId = Guid.NewGuid(), ticketNumber = "TCK-000001", verified = true, againstId = Guid.NewGuid(), actorId = actor },
        ["billing.CommissionCharged"] = new { providerId = Guid.NewGuid(), bookingId = Guid.NewGuid(), amountPaisa = 113, duePaisa = 113 },
        ["billing.PaymentSubmitted"] = new { submissionId = Guid.NewGuid(), providerId = Guid.NewGuid(), amountPaisa = 100, method = "bkash", duePaisa = 113, actorId = actor },
        ["billing.PaymentConfirmed"] = new { submissionId = Guid.NewGuid(), providerId = Guid.NewGuid(), amountPaisa = 100, method = "bkash", duePaisa = 13, actorId = actor },
        ["billing.PaymentRejected"] = new { submissionId = Guid.NewGuid(), providerId = Guid.NewGuid(), amountPaisa = 100, method = "bkash", duePaisa = 113, reason = "no such transaction", actorId = actor },
    };

    [Fact]
    public async Task Audits_every_subscribed_event_once_per_delivery_and_rejects_broken_payloads()
    {
        var repo = new MemoryEntries();
        var services = new ServiceCollection()
            .AddSingleton<IAuditRepository>(repo)
            .AddSingleton<IClock>(new FakeClock(Now))
            .AddSingleton<IIdGenerator, UuidV7Generator>()
            .AddScoped<AuditLog>()
            .BuildServiceProvider();
        var bus = new EventBus();
        new AuditSubscriptions(services.GetRequiredService<IServiceScopeFactory>()).Subscribe(bus);
        var actor = Guid.NewGuid();
        var payloads = Payloads(actor);
        Assert.Equal(payloads.Keys.Order(), EventEntries.Maps.Keys.Order());
        foreach (var (name, payload) in payloads)
        {
            Envelope Of(object body) => new() { Id = Guid.NewGuid(), Module = "m", Name = name, AggregateId = string.Empty, OccurredAt = Now, Payload = JsonSerializer.SerializeToElement(body, JsonSerializerOptions.Web) };
            await bus.Dispatch(Of(payload), CancellationToken.None);
            await Assert.ThrowsAsync<EventDeliveryException>(() => bus.Dispatch(Of(new { name }), CancellationToken.None));
        }
        Assert.Equal(13, repo.Entries.Count);
        var first = repo.Entries[0].Entry;
        Assert.Equal(("account.status_changed", (Guid?)actor, "active", "banned"), (first.Action, first.ActorId, (string?)first.Before!["status"], (string?)first.After!["status"]));
        Assert.All(repo.Entries, e => Assert.Equal((Now, true), (e.Entry.At, e.EventId is not null)));
        Assert.Null(repo.Entries[1].Entry.ActorId);
    }

    [Fact]
    public async Task Pages_with_one_entry_more_than_asked()
    {
        var repo = new MemoryEntries();
        var log = new AuditLog(repo, new FakeClock(Now), new UuidV7Generator());
        for (var i = 0; i < 3; i++)
        {
            await log.Record(Entry(), null, CancellationToken.None);
        }
        var handler = new ListAuditEntriesHandler(log, new Mapper([new AuditMappingProfile()]));
        var page = await handler.Handle(new ListAuditEntriesQuery(new AuditFilter(), null, 2), CancellationToken.None);
        Assert.Equal(2, page.Items.Count);
        Assert.NotNull(Cursor(page.NextCursor));
        var last = await handler.Handle(new ListAuditEntriesQuery(new AuditFilter(), page.NextCursor, 5), CancellationToken.None);
        Assert.Null(last.NextCursor);
        Assert.True(new ListAuditEntriesValidator().Validate(new ListAuditEntriesQuery(new AuditFilter(), null, null)).IsValid);
    }

    private static PAO.Infrastructure.Http.Cursor? Cursor(string? text) => PAO.Infrastructure.Http.Cursor.Decode(text);
}
