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
        var logger = services.GetRequiredService<ILoggerFactory>().CreateLogger("PAO");
        logger.LogInformation("platform ready {@Config}", settings.LogFields());
        WarnWhenSmsVerificationIsOff(settings, logger);
    }

    /// <summary>
    /// Logs a warning at every start while SMS verification is off, so a deployment that
    /// accepts the fixed code for every phone is never mistaken for a normal one.
    /// </summary>
    public static void WarnWhenSmsVerificationIsOff(PaoSettings settings, ILogger logger)
    {
        if (!settings.Sms.VerificationEnabled)
        {
            logger.LogWarning(
                "SMS verification is OFF: no SMS is sent and every phone code is the fixed SMS_FIXED_CODE; set SMS_VERIFICATION_ENABLED=true once an SMS provider is configured");
        }
    }
}
