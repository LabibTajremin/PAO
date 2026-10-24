using Microsoft.Extensions.DependencyInjection;
using Npgsql;
using PAO.EF;
using PAO.EF.Connection;

namespace PAO.Infrastructure.Data;

/// <summary>Registers Postgres: one data source, the DbContext factory and a scoped context.</summary>
public static class DatabaseSetup
{
    /// <summary>Adds the data source for `databaseUrl` and <see cref="PaoDbContext"/>.</summary>
    public static IServiceCollection AddPaoDatabase(this IServiceCollection services, string databaseUrl)
    {
        var dataSource = PaoDbContextSetup.CreateDataSource(PostgresUrl.ToConnectionString(databaseUrl));
        services.AddSingleton(dataSource);
        services.AddDbContextFactory<PaoDbContext>(options => PaoDbContextSetup.Configure(options, dataSource));
        return services;
    }

    /// <summary>Checks that the database answers; the hosts call it at start to fail fast.</summary>
    public static async Task Ping(NpgsqlDataSource dataSource, CancellationToken cancellationToken)
    {
        await using var command = dataSource.CreateCommand("SELECT 1");
        await command.ExecuteScalarAsync(cancellationToken);
    }
}

/// <summary>Postgres error helpers.</summary>
public static class PostgresErrors
{
    /// <summary>
    /// Reports whether `error` (or a cause) is a unique-constraint violation, optionally on
    /// the named constraint.
    /// </summary>
    public static bool IsUniqueViolation(Exception? error, string? constraint = null)
    {
        for (var e = error; e is not null; e = e.InnerException)
        {
            if (e is PostgresException { SqlState: PostgresErrorCodes.UniqueViolation } pg)
            {
                return string.IsNullOrEmpty(constraint) || pg.ConstraintName == constraint;
            }
        }
        return false;
    }

    /// <summary>Quotes `"schema"."table"`; names only ever come from code.</summary>
    public static string QualifiedTable(string schema, string table) => $"{Quote(schema)}.{Quote(table)}";

    /// <summary>Quotes one identifier, doubling embedded quotes.</summary>
    public static string Quote(string identifier) => "\"" + identifier.Replace("\"", "\"\"", StringComparison.Ordinal) + "\"";
}
