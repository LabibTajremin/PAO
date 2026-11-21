using Microsoft.EntityFrameworkCore;
using Npgsql;

namespace PAO.EF;

/// <summary>
/// Configures <see cref="PaoDbContext"/> the same way for the hosts, the design-time
/// factory and the tests: Npgsql with NetTopologySuite (PostGIS) and no tracking by
/// default, so reads never pay for change tracking they do not use.
/// </summary>
public static class PaoDbContextSetup
{
    /// <summary>Builds the data source every connection of the process comes from.</summary>
    public static NpgsqlDataSource CreateDataSource(string connectionString)
    {
        var builder = new NpgsqlDataSourceBuilder(connectionString);
        builder.UseNetTopologySuite();
        return builder.Build();
    }

    /// <summary>Points `options` at `dataSource`.</summary>
    public static void Configure(DbContextOptionsBuilder options, NpgsqlDataSource dataSource)
    {
        options
            .UseNpgsql(dataSource, npgsql => npgsql.UseNetTopologySuite())
            .UseQueryTrackingBehavior(QueryTrackingBehavior.NoTracking);
    }
}
