using System.Text.Json;
using Microsoft.Extensions.Logging;
using Npgsql;
using PAO.Infrastructure.Data;
using PAO.Infrastructure.Events;

namespace PAO.Infrastructure.Outbox;

/// <summary>Told about every delivery attempt; the worker's metrics implement it.</summary>
public interface IRelayObserver
{
    /// <summary>An event reached every subscriber.</summary>
    void EventDelivered(string module, string eventName);

    /// <summary>An attempt failed; `dead` when the event was dead-lettered.</summary>
    void EventFailed(string module, string eventName, bool dead);
}

/// <summary>
/// Moves events from every area's outbox to the bus: at least once, in order per
/// aggregate, retrying with exponential backoff (capped at five minutes) and
/// dead-lettering after <see cref="MaxAttempts"/>.
/// </summary>
public sealed class OutboxRelay(NpgsqlDataSource dataSource, IEventDispatcher bus, IReadOnlyList<string> modules, IClock clock, IRelayObserver observer, ILogger<OutboxRelay> logger)
{
    /// <summary>How often an event is tried before it is dead-lettered.</summary>
    public const int MaxAttempts = 10;
    private const int Batch = 100;
    private static readonly TimeSpan MaxBackoff = TimeSpan.FromMinutes(5);

    /// <summary>Relays one batch from each module and returns how many events it delivered.</summary>
    public async Task<int> RunOnce(CancellationToken cancellationToken)
    {
        var total = 0;
        foreach (var module in modules)
        {
            await using var connection = await dataSource.OpenConnectionAsync(cancellationToken);
            await using var transaction = await connection.BeginTransactionAsync(cancellationToken);
            total += await RelayModule(connection, module, cancellationToken);
            await transaction.CommitAsync(cancellationToken);
        }
        return total;
    }

    private async Task<int> RelayModule(NpgsqlConnection connection, string module, CancellationToken cancellationToken)
    {
        var table = PostgresErrors.QualifiedTable(module, "outbox");
        var rows = await Pending(connection, module, table, cancellationToken);
        var now = clock.Now;
        var blocked = new HashSet<string>(StringComparer.Ordinal);
        var delivered = 0;
        foreach (var row in rows)
        {
            // An aggregate's events stay in order: once one waits, later ones wait too.
            if (blocked.Contains(row.Envelope.AggregateId) || row.NotBefore > now)
            {
                blocked.Add(row.Envelope.AggregateId);
                continue;
            }
            var failure = await Deliver(row.Envelope, cancellationToken);
            if (failure is null)
            {
                await Record(connection, table, "UPDATE {0} SET published_at = $2, attempts = attempts + 1 WHERE id = $1", cancellationToken, row.Envelope.Id, clock.Now);
                observer.EventDelivered(module, row.Envelope.Name);
                delivered++;
                continue;
            }
            blocked.Add(row.Envelope.AggregateId);
            observer.EventFailed(module, row.Envelope.Name, await RecordFailure(connection, table, row, failure, cancellationToken));
        }
        return delivered;
    }

    private async Task<Exception?> Deliver(Envelope envelope, CancellationToken cancellationToken)
    {
        try
        {
            await bus.Dispatch(envelope, cancellationToken);
            return null;
        }
        catch (Exception error) when (error is not OperationCanceledException)
        {
            return error;
        }
    }

    private async Task<bool> RecordFailure(NpgsqlConnection connection, string table, PendingRow row, Exception failure, CancellationToken cancellationToken)
    {
        var attempts = row.Attempts + 1;
        var dead = attempts >= MaxAttempts;
        var backoff = TimeSpan.FromSeconds(Math.Min(Math.Pow(2, Math.Min(attempts, 9)), MaxBackoff.TotalSeconds));
        logger.LogWarning(failure, "event delivery failed {Event} {Id} attempt {Attempt}", row.Envelope.Name, row.Envelope.Id, attempts);
        await Record(connection, table, "UPDATE {0} SET attempts = $2, next_attempt_at = $3, last_error = $4, dead = $5 WHERE id = $1",
            cancellationToken, row.Envelope.Id, attempts, clock.Now + backoff, failure.Message, dead);
        return dead;
    }

    private static async Task Record(NpgsqlConnection connection, string table, string sql, CancellationToken cancellationToken, params object[] values)
    {
        await using var command = new NpgsqlCommand(string.Format(System.Globalization.CultureInfo.InvariantCulture, sql, table), connection);
        foreach (var value in values)
        {
            command.Parameters.Add(new NpgsqlParameter { Value = value });
        }
        await command.ExecuteNonQueryAsync(cancellationToken);
    }

    private static async Task<List<PendingRow>> Pending(NpgsqlConnection connection, string module, string table, CancellationToken cancellationToken)
    {
        await using var command = new NpgsqlCommand(
            $"SELECT id, aggregate_id, event_name, payload::text, created_at, attempts, next_attempt_at FROM {table} " +
            "WHERE published_at IS NULL AND NOT dead ORDER BY created_at, id LIMIT $1 FOR UPDATE SKIP LOCKED", connection);
        command.Parameters.Add(new NpgsqlParameter { Value = Batch });
        await using var reader = await command.ExecuteReaderAsync(cancellationToken);
        var rows = new List<PendingRow>();
        while (await reader.ReadAsync(cancellationToken))
        {
            using var payload = JsonDocument.Parse(reader.GetString(3));
            rows.Add(new PendingRow(
                new Envelope
                {
                    Id = reader.GetGuid(0),
                    Module = module,
                    AggregateId = reader.GetString(1),
                    Name = reader.GetString(2),
                    Payload = payload.RootElement.Clone(),
                    OccurredAt = reader.GetFieldValue<DateTimeOffset>(4),
                },
                reader.GetInt32(5),
                reader.GetFieldValue<DateTimeOffset>(6)));
        }
        return rows;
    }

    private sealed record PendingRow(Envelope Envelope, int Attempts, DateTimeOffset NotBefore);
}
