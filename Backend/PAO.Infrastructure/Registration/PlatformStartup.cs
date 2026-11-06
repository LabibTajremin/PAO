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
    /// <summary>The `host` name of the API process.</summary>
    public const string ApiHostName = "api";

    /// <summary>The `host` name of the worker process.</summary>
    public const string WorkerHostName = "worker";

    /// <summary>
    /// Fails fast at start: the database and Redis must answer and the
    /// buckets must exist (created with default encryption when missing). `host` is
    /// <see cref="ApiHostName"/> or <see cref="WorkerHostName"/>.
    /// </summary>
    public static async Task Prepare(this IServiceProvider services, string host, CancellationToken cancellationToken)
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
        LogBackgroundJobs(settings, host, logger);
    }

    /// <summary>
    /// Logs which process runs the outbox relay and the jobs: `background jobs: in api` when
    /// the API runs them (JOBS_IN_API=true, ADR-0036 §14), else `background jobs: in worker`.
    /// A worker that sees JOBS_IN_API=true warns, as the API then runs them too.
    /// </summary>
    public static void LogBackgroundJobs(PaoSettings settings, string host, ILogger logger)
    {
        if (host == ApiHostName && settings.Jobs.RunInApi)
        {
            logger.LogInformation("background jobs: in api");
            return;
        }
        logger.LogInformation("background jobs: in worker");
        if (host == WorkerHostName && settings.Jobs.RunInApi)
        {
            // Safe (advisory locks, SKIP LOCKED, idempotent handlers) but every pass runs twice.
            logger.LogWarning(
                "JOBS_IN_API is true here too: the API also runs the background jobs; run either the worker or JOBS_IN_API=true, not both");
        }
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
