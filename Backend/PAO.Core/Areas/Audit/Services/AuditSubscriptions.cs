using PAO.Infrastructure.Events;

namespace PAO.Core.Areas.Audit.Services;

/// <summary>
/// Writes an entry for every audited event in the worker. Entries carry the event id, so a
/// redelivered event cannot add a second one.
/// </summary>
public sealed class AuditSubscriptions(IServiceScopeFactory scopes) : IEventSubscriptions
{
    /// <summary>The handler name on the bus.</summary>
    public const string Handler = "audit";

    /// <inheritdoc />
    public void Subscribe(EventBus bus)
    {
        foreach (var (name, toEntry) in EventEntries.Maps)
        {
            bus.Subscribe(name, Handler, (envelope, cancellationToken) => Record(toEntry, envelope, cancellationToken));
        }
    }

    private async Task Record(Func<EventPayload, PAO.Lib.Areas.Audit.AuditEntry> toEntry, Envelope envelope, CancellationToken cancellationToken)
    {
        var entry = toEntry(new EventPayload(envelope)) with { At = envelope.OccurredAt };
        await using var scope = scopes.CreateAsyncScope();
        await scope.ServiceProvider.GetRequiredService<AuditLog>().Record(entry, envelope.Id, cancellationToken);
    }
}
