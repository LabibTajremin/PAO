using System.Reflection;
using Microsoft.Extensions.DependencyInjection;
using PAO.Infrastructure.Configuration;
using PAO.Infrastructure.Crypto;
using PAO.Infrastructure.Data;
using PAO.Infrastructure.Mediation;
using PAO.Infrastructure.Metrics;
using PAO.Infrastructure.Outbox;
using PAO.Infrastructure.Push;
using PAO.Infrastructure.Rbac;
using PAO.Infrastructure.Redis;
using PAO.Infrastructure.Sms;
using PAO.Infrastructure.Storage;
using PAO.Infrastructure.Testing;
using StackExchange.Redis;

namespace PAO.Infrastructure.Registration;

/// <summary>Hand-made platform services: mediator, mapper, clock, ids, crypto, Redis helpers, storage, SMS, push, outbox, metrics.</summary>
public static class CustomServicesRegistration
{
    /// <summary>Adds the platform services; `featureAssemblies` are scanned for handlers, validators and mapping profiles.</summary>
    public static IServiceCollection AddCustomServices(this IServiceCollection services, PaoSettings settings, params Assembly[] featureAssemblies)
    {
        services.AddMediator(featureAssemblies);
        services.AddSingleton<IClock, SystemClock>();
        services.AddSingleton<IIdGenerator, UuidV7Generator>();
        services.AddSingleton<ReferenceDataCache>();
        services.AddSingleton<PaoMetrics>();
        services.AddSingleton<OutboxWriter>();
        services.AddSingleton<IdempotentEventHandler>();
        services.AddSingleton(new ObjectStore(settings.Storage));
        AddRedis(services, settings);
        AddCrypto(services, settings);
        AddSms(services, settings);
        AddPush(services, settings);
        return services;
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

    private static void AddSms(IServiceCollection services, PaoSettings settings)
    {
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
    }

    private static void AddPush(IServiceCollection services, PaoSettings settings)
    {
        if (settings.Push.Adapter == "fcm")
        {
            services.AddSingleton<IPushSender>(sp =>
            {
                var account = ServiceAccount.Parse(File.ReadAllText(settings.Push.FcmCredentialsFile));
                var http = sp.GetRequiredService<IHttpClientFactory>();
                var tokens = new GoogleAccessTokens(http.CreateClient(), account, sp.GetRequiredService<IClock>());
                return new FcmPushSender(http.CreateClient(), FcmPushSender.EndpointFor(account.ProjectId), tokens);
            });
            return;
        }
        services.AddSingleton<CapturePushSender>();
        services.AddSingleton<IPushSender>(sp => sp.GetRequiredService<CapturePushSender>());
        services.AddSingleton<IPushCapture>(sp => sp.GetRequiredService<CapturePushSender>());
    }
}
