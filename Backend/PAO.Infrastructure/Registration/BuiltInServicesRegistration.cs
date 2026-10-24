using Microsoft.Extensions.DependencyInjection;
using Microsoft.Extensions.Options;
using Npgsql;
using PAO.Infrastructure.Configuration;
using PAO.Infrastructure.Data;
using PAO.Infrastructure.Health;
using PAO.Infrastructure.Http;
using PAO.Infrastructure.Storage;
using StackExchange.Redis;

namespace PAO.Infrastructure.Registration;

/// <summary>Framework services: options, HTTP clients, health checks and, for the API, controllers with the HTTP edge.</summary>
public static class BuiltInServicesRegistration
{
    /// <summary>
    /// Adds the framework services. `specPath` is the bundled OpenAPI document; when given,
    /// MVC controllers are added with the edge filters (authentication, authorisation,
    /// rate limiting, validation, idempotency) and the controllers of `controllerAssembly`.
    /// </summary>
    public static IServiceCollection AddBuiltInServices(
        this IServiceCollection services, PaoSettings settings, string? specPath = null, System.Reflection.Assembly? controllerAssembly = null)
    {
        services.AddSingleton(Options.Create(settings.App));
        services.AddSingleton(Options.Create(settings.Jwt));
        services.AddSingleton(Options.Create(settings.Http));
        services.AddSingleton(Options.Create(settings.Jobs));
        services.AddSingleton(Options.Create(settings.Smtp));
        services.AddHttpClient();
        services.AddSingleton(sp => new HealthCheck("database", ct => DatabaseSetup.Ping(sp.GetRequiredService<NpgsqlDataSource>(), ct)));
        services.AddSingleton(sp => new HealthCheck("redis", _ => sp.GetRequiredService<IConnectionMultiplexer>().GetDatabase().PingAsync()));
        services.AddSingleton(sp => new HealthCheck("storage", ct => sp.GetRequiredService<ObjectStore>().Ping(settings.Storage.BucketPrivate, ct)));
        if (specPath is not null)
        {
            var mvc = services.AddHttpEdge(specPath);
            if (controllerAssembly is not null)
            {
                mvc.AddApplicationPart(controllerAssembly);
            }
        }
        return services;
    }
}
