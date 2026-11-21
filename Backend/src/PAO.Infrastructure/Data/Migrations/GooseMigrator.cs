using Npgsql;

namespace PAO.Infrastructure.Data.Migrations;

/// <summary>
/// Applies the per-module goose migrations with goose's rules: each
/// module keeps its own version table, `goose_&lt;module&gt;`, in the exact shape goose v3
/// creates, so a database either backend migrated is up to date for the other.
/// </summary>
public sealed class GooseMigrator(NpgsqlDataSource dataSource, Func<string, IReadOnlyList<GooseMigration>> load, IReadOnlyList<string> modules)
{
    // Serialises concurrent migrators (two deploys starting at once); same key as earlier releases.
    private const long MigrationLockKey = 7_041_998_310;

    /// <summary>Applies every pending migration of every module, in module order.</summary>
    public Task Up(CancellationToken cancellationToken) => Locked(async connection =>
    {
        foreach (var module in modules)
        {
            await ModuleUp(connection, module, cancellationToken);
        }
    }, cancellationToken);

    /// <summary>Rolls every module back to version zero, in reverse module order.</summary>
    public Task Down(CancellationToken cancellationToken) => Locked(async connection =>
    {
        foreach (var module in modules.Reverse())
        {
            await ModuleDown(connection, module, cancellationToken);
        }
    }, cancellationToken);

    private async Task Locked(Func<NpgsqlConnection, Task> run, CancellationToken cancellationToken)
    {
        await using var connection = await dataSource.OpenConnectionAsync(cancellationToken);
        await Sql.Execute(connection, "SELECT pg_advisory_lock($1)", cancellationToken, MigrationLockKey);
        try
        {
            await run(connection);
        }
        finally
        {
            await Sql.Execute(connection, "SELECT pg_advisory_unlock($1)", CancellationToken.None, MigrationLockKey);
        }
    }

    private async Task ModuleUp(NpgsqlConnection connection, string module, CancellationToken cancellationToken)
    {
        var migrations = load(module);
        var table = await VersionTable.Ensure(connection, module, cancellationToken);
        var applied = await VersionTable.Applied(connection, table, cancellationToken);
        var latest = applied.Max();
        var pending = migrations.Where(m => !applied.Contains(m.Version)).ToList();
        var missing = pending.Where(m => m.Version < latest).Select(m => m.Source).ToList();
        if (missing.Count > 0)
        {
            throw new InvalidOperationException(
                $"migrate {module} up: found {missing.Count} missing (out-of-order) migration(s): {string.Join(", ", missing)}");
        }
        foreach (var m in pending)
        {
            await Apply(connection, m, m.Up, $"INSERT INTO {table} (version_id, is_applied) VALUES ($1, true)", cancellationToken);
        }
    }

    private async Task ModuleDown(NpgsqlConnection connection, string module, CancellationToken cancellationToken)
    {
        var migrations = load(module).ToDictionary(m => m.Version);
        var table = await VersionTable.Ensure(connection, module, cancellationToken);
        var applied = await VersionTable.Applied(connection, table, cancellationToken);
        foreach (var version in applied.Where(v => v > 0).OrderDescending())
        {
            var m = migrations.GetValueOrDefault(version)
                ?? throw new InvalidOperationException($"migrate {module} down: no file for applied version {version}");
            await Apply(connection, m, m.Down, $"DELETE FROM {table} WHERE version_id = $1", cancellationToken);
        }
    }

    private static async Task Apply(
        NpgsqlConnection connection, GooseMigration m, IReadOnlyList<string> statements, string record, CancellationToken cancellationToken)
    {
        async Task Run()
        {
            foreach (var statement in statements)
            {
                await Sql.Execute(connection, statement, cancellationToken);
            }
            await Sql.Execute(connection, record, cancellationToken, m.Version);
        }
        try
        {
            await (m.NoTransaction ? Run() : Sql.InTransaction(connection, Run, cancellationToken));
        }
        catch (NpgsqlException e)
        {
            throw new InvalidOperationException($"migration {m.Source} failed", e);
        }
    }
}
