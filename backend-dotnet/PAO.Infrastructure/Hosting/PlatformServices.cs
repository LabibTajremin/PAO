using Microsoft.Extensions.DependencyInjection;
using Microsoft.Extensions.Logging;
using Microsoft.Extensions.Options;
using Npgsql;
using PAO.Infrastructure.Configuration;
using PAO.Infrastructure.Crypto;
using PAO.Infrastructure.Data;
using PAO.Infrastructure.Health;
using PAO.Infrastructure.Metrics;
using PAO.Infrastructure.Outbox;
using PAO.Infrastructure.Push;
using PAO.Infrastructure.Rbac;
using PAO.Infrastructure.Redis;
using PAO.Infrastructure.Sms;
using PAO.Infrastructure.Storage;
using PAO.Infrastructure.Testing;
using StackExchange.Redis;

namespace PAO.Infrastructure.Hosting;

/// <summary>Registers the platform every host shares, from validated settings.</summary>
public static class PlatformServices
{
    /// <summary>Adds configuration, data, Redis, crypto, storage, SMS, push, metrics and health.</summary>
    public static IServiceCollection AddPlatform(this IServiceCollection services, PaoSettings settings)
    {
        AddOptions(services, settings);
        services.AddSingleton<IClock, SystemClock>();
        services.AddSingleton<IIdGenerator, UuidV7Generator>();
        services.AddSingleton<ReferenceDataCache>();
        services.AddPaoDatabase(settings.Database.Url);
        AddRedis(services, settings);
        AddCrypto(services, settings);
        services.AddSingleton(new ObjectStore(settings.Storage));
        services.AddSingleton<PaoMetrics>();
        services.AddSingleton<OutboxWriter>();
        services.AddSingleton<IdempotentEventHandler>();
        AddMessaging(services, settings);
        AddHealthChecks(services, settings);
        return services;
    }

    private static void AddOptions(IServiceCollection services, PaoSettings s)
    {
        services.AddSingleton(Options.Create(s.App));
        services.AddSingleton(Options.Create(s.Jwt));
        services.AddSingleton(Options.Create(s.Http));
        services.AddSingleton(Options.Create(s.Jobs));
        services.AddSingleton(Options.Create(s.Smtp));
        services.AddSingleton(s);
    }

    private static void AddRedis(IServiceCollection services, PaoSettings settings)
    {
        services.AddSingleton<IConnectionMultiplexer>(_ => ConnectionMultiplexer.Connect(RedisUrl.Parse(settings.Redis.Url)));
        services.AddSingleton(new RedisKeys(settings.App.Environment));
        services.AddSingleton<RateLimiter>();
        services.AddSingleton<Locker>();
        services.AddSingleton<IdempotencyStore>();
        services.AddSingleton<JsonCache>();
        services.AddSingleton<Denylist>();
        services.AddSingleton<IRbacSource, EfRbacSource>();
        services.AddSingleton<RbacChecker>();
    }

    private static void AddCrypto(IServiceCollection services, PaoSettings settings)
    {
        var ring = JwtKeyRing.From(settings.Jwt);
        services.AddSingleton(ring);
        services.AddSingleton(sp => new TokenSigner(ring.Signing, sp.GetRequiredService<IClock>(), sp.GetRequiredService<IIdGenerator>()));
        services.AddSingleton(sp => new TokenVerifier(ring.VerificationKeys, sp.GetRequiredService<IClock>()));
        services.AddSingleton(new DataCipher(StrictBase64.Decode(settings.App.DataEncryptionKey)!));
    }

    private static void AddMessaging(IServiceCollection services, PaoSettings settings)
    {
        services.AddHttpClient();
        if (settings.Sms.Adapter == "sslwireless")
        {
            services.AddSingleton<ISmsSender>(sp => new SslWirelessSmsSender(
                sp.GetRequiredService<IHttpClientFactory>().CreateClient(), settings.Sms, sp.GetRequiredService<IIdGenerator>()));
        }
        else if (settings.App.Environment == AppEnvironments.Test)
        {
            services.AddSingleton<CapturedSmsSender>();
            services.AddSingleton<ISmsSender>(sp => sp.GetRequiredService<CapturedSmsSender>());
            services.AddSingleton<ISmsCapture>(sp => sp.GetRequiredService<CapturedSmsSender>());
        }
        else
        {
            services.AddSingleton<ISmsSender, ConsoleSmsSender>();
        }
        if (settings.Push.Adapter == "fcm")
        {
            services.AddSingleton<IPushSender>(sp => FcmFrom(sp, settings.Push));
            return;
        }
        services.AddSingleton<CapturePushSender>();
        services.AddSingleton<IPushSender>(sp => sp.GetRequiredService<CapturePushSender>());
        services.AddSingleton<IPushCapture>(sp => sp.GetRequiredService<CapturePushSender>());
    }

    private static FcmPushSender FcmFrom(IServiceProvider sp, PushOptions push)
    {
        var account = ServiceAccount.Parse(File.ReadAllText(push.FcmCredentialsFile));
        var http = sp.GetRequiredService<IHttpClientFactory>();
        var tokens = new GoogleAccessTokens(http.CreateClient(), account, sp.GetRequiredService<IClock>());
        return new FcmPushSender(http.CreateClient(), FcmPushSender.EndpointFor(account.ProjectId), tokens);
    }

    private static void AddHealthChecks(IServiceCollection services, PaoSettings settings)
    {
        services.AddSingleton(sp => new HealthCheck("database", ct => DatabaseSetup.Ping(sp.GetRequiredService<NpgsqlDataSource>(), ct)));
        services.AddSingleton(sp => new HealthCheck("redis", _ => sp.GetRequiredService<IConnectionMultiplexer>().GetDatabase().PingAsync()));
        services.AddSingleton(sp => new HealthCheck("storage", ct => sp.GetRequiredService<ObjectStore>().Ping(settings.Storage.BucketPrivate, ct)));
    }

    /// <summary>
    /// Fails fast at start, as NestJS did: the database and Redis must answer and the
    /// buckets must exist (created with default encryption when missing).
    /// </summary>
    public static async Task Prepare(IServiceProvider services, CancellationToken cancellationToken)
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
