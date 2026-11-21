using Microsoft.EntityFrameworkCore;
using Microsoft.EntityFrameworkCore.Design;
using PAO.EF.Connection;

namespace PAO.EF;

/// <summary>
/// Lets `dotnet ef` tooling (scaffolding, compiled models) build the context from
/// DATABASE_URL. It never creates migrations: the scripts in "DB Changes" own the schema.
/// </summary>
public sealed class DesignTimeDbContextFactory : IDesignTimeDbContextFactory<PaoDbContext>
{
    /// <summary>The URL used when DATABASE_URL is unset: the local docker compose database.</summary>
    public const string LocalDatabaseUrl = "postgres://pao:pao@localhost:5432/pao?sslmode=disable";

    /// <inheritdoc />
    public PaoDbContext CreateDbContext(string[] args)
    {
        var url = Environment.GetEnvironmentVariable("DATABASE_URL");
        var dataSource = PaoDbContextSetup.CreateDataSource(
            PostgresUrl.ToConnectionString(string.IsNullOrEmpty(url) ? LocalDatabaseUrl : url));
        var options = new DbContextOptionsBuilder<PaoDbContext>();
        PaoDbContextSetup.Configure(options, dataSource);
        return new PaoDbContext(options.Options);
    }
}
