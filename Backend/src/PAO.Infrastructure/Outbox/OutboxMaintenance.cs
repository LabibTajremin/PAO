using Npgsql;
using PAO.Infrastructure.Data;

namespace PAO.Infrastructure.Outbox;

/// <summary>One module's undelivered events, as the worker's metrics report them.</summary>
public sealed record OutboxBacklog(string Module, long Pending, long Dead, double OldestSeconds);

/// <summary>Purges delivered events and reads the backlog of every module's outbox.</summary>
public sealed class OutboxMaintenance(NpgsqlDataSource dataSource, IReadOnlyList<string> modules)
{
    /// <summary>Deletes events delivered before `cutoff`; dead letters stay for inspection.</summary>
    public async Task PurgePublished(DateTimeOffset cutoff, CancellationToken cancellationToken)
    {
        await using var batch = dataSource.CreateBatch();
        foreach (var module in modules)
        {
            var command = new NpgsqlBatchCommand($"DELETE FROM {PostgresErrors.QualifiedTable(module, "outbox")} WHERE published_at < $1");
            command.Parameters.Add(new NpgsqlParameter { Value = cutoff });
            batch.BatchCommands.Add(command);
        }
        await batch.ExecuteNonQueryAsync(cancellationToken);
    }

    /// <summary>Reads each module's backlog as of `now`, in one round trip.</summary>
    public async Task<IReadOnlyList<OutboxBacklog>> Backlog(DateTimeOffset now, CancellationToken cancellationToken)
    {
        var selects = modules.Select((module, i) =>
            $"SELECT {i} AS ord, count(*) FILTER (WHERE NOT dead), count(*) FILTER (WHERE dead), min(created_at) FILTER (WHERE NOT dead) " +
            $"FROM {PostgresErrors.QualifiedTable(module, "outbox")} WHERE published_at IS NULL");
        await using var command = dataSource.CreateCommand(string.Join(" UNION ALL ", selects) + " ORDER BY ord");
        await using var reader = await command.ExecuteReaderAsync(cancellationToken);
        var backlog = new List<OutboxBacklog>();
        while (await reader.ReadAsync(cancellationToken))
        {
            var oldest = reader.IsDBNull(3) ? (DateTimeOffset?)null : reader.GetFieldValue<DateTimeOffset>(3);
            var age = oldest is { } at ? Math.Max(0, (now - at).TotalSeconds) : 0;
            backlog.Add(new OutboxBacklog(modules[reader.GetInt32(0)], reader.GetInt64(1), reader.GetInt64(2), age));
        }
        return backlog;
    }
}
