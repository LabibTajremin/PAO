using Microsoft.Extensions.DependencyInjection;
using Microsoft.Extensions.Logging;
using Npgsql;
using PAO.Infrastructure.Configuration;
using PAO.Infrastructure.Data;
using PAO.Infrastructure.Storage;
using StackExchange.Redis;

namespace PAO.Infrastructure.Registration;

/// <summary>The start-up checks every host runs before it serves.</summary>
public static class PlatformStartup
{
    /// <summary>
    /// Fails fast at start: the database and Redis must answer and the
    /// buckets must exist (created with default encryption when missing).
    /// </summary>
    public static async Task Prepare(this IServiceProvider services, CancellationToken cancellationToken)
    {
        var settings = services.GetRequiredService<PaoSettings>();
        await DatabaseSetup.Ping(services.GetRequiredService<NpgsqlDataSource>(), cancellationToken);
        await services.GetRequiredService<IConnectionMultiplexer>().GetDatabase().PingAsync();
        var store = services.GetRequiredService<ObjectStore>();
        await store.EnsureBucket(settings.Storage.BucketPrivate, cancellationToken);
        await store.EnsureBucket(settings.Storage.BucketPublic, cancellationToken);
        services.GetRequiredService<ILoggerFactory>().CreateLogger("PAO").LogInformation("platform ready {@Config}", settings.LogFields());
    }
}
