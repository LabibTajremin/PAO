using System.Text.Json;
using Microsoft.EntityFrameworkCore;
using Npgsql;
using NpgsqlTypes;
using PAO.EF;
using PAO.Infrastructure.Data;
using PAO.Infrastructure.Events;
using PAO.Lib.Events;

namespace PAO.Infrastructure.Outbox;

/// <summary>
/// Appends events to an area's outbox inside the caller's transaction, so an event is
/// stored exactly when the change that caused it commits (PRD §9.3 rule 5).
/// </summary>
public sealed class OutboxWriter(IIdGenerator ids, IClock clock)
{
    /// <summary>Event payloads are camelCase JSON, field for field what existing rows hold.</summary>
    public static readonly JsonSerializerOptions Json = new(JsonSerializerDefaults.Web);

    /// <summary>Stores `domainEvent` for `aggregateId` in `{schema}.outbox` through `db`'s connection and transaction.</summary>
    public async Task Write(PaoDbContext db, string schema, string aggregateId, IDomainEvent domainEvent, CancellationToken cancellationToken)
    {
        var table = PostgresErrors.QualifiedTable(schema, "outbox");
        var now = clock.Now;
        // The table name is a quoted identifier built from code; values are parameters.
        var sql = $"INSERT INTO {table} (id, aggregate_id, event_name, payload, created_at, next_attempt_at) VALUES (@id, @aggregate, @name, @payload, @at, @at)";
        await db.Database.ExecuteSqlRawAsync(
            sql,
            [
                new NpgsqlParameter("id", ids.NewId()),
                new NpgsqlParameter("aggregate", aggregateId),
                new NpgsqlParameter("name", domainEvent.Name),
                new NpgsqlParameter("payload", NpgsqlDbType.Jsonb) { Value = JsonSerializer.Serialize(domainEvent, domainEvent.GetType(), Json) },
                new NpgsqlParameter("at", now),
            ],
            cancellationToken);
    }
}

/// <summary>
/// Wraps an area's subscriber so each event is applied once per handler: the
/// processed-event row and the handler's writes commit together, and a redelivered event
/// is skipped.
/// </summary>
public sealed class IdempotentEventHandler(IDbContextFactory<PaoDbContext> contexts)
{
    /// <summary>The bus handler that runs `handle` once per event for `handlerName` in `schema`.</summary>
    public EventSubscriber Wrap(string schema, string handlerName, Func<PaoDbContext, Envelope, CancellationToken, Task> handle) =>
        async (envelope, cancellationToken) =>
        {
            await using var db = await contexts.CreateDbContextAsync(cancellationToken);
            await using var transaction = await db.Database.BeginTransactionAsync(cancellationToken);
            var sql = $"INSERT INTO {PostgresErrors.QualifiedTable(schema, "processed_events")} (handler, event_id) VALUES (@handler, @event) ON CONFLICT DO NOTHING";
            var inserted = await db.Database.ExecuteSqlRawAsync(
                sql,
                [new NpgsqlParameter("handler", handlerName), new NpgsqlParameter("event", envelope.Id)],
                cancellationToken);
            if (inserted != 0)
            {
                await handle(db, envelope, cancellationToken);
            }
            await transaction.CommitAsync(cancellationToken);
        };
}
