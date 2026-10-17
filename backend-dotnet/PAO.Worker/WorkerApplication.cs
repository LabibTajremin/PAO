using System.Collections;
using PAO.BackgroundJobs;
using PAO.Core;
using PAO.Core.Areas;
using PAO.Infrastructure.Configuration;
using PAO.Infrastructure.Data.Migrations;
using PAO.Infrastructure.Hosting;
using PAO.Infrastructure.Logging;
using PAO.Infrastructure.Mediation;
using PAO.Infrastructure.Testing;
using Serilog;

namespace PAO.Worker;

/// <summary>
/// Builds the worker host: the same platform and areas as the API, plus every area's event
/// subscribers behind the outbox relay and every periodic job (02-architecture §9).
/// </summary>
public static class WorkerApplication
{
    /// <summary>Builds the host; `configure` lets tests swap services before it is built.</summary>
    public static (IHost Host, PaoSettings Settings) Build(
        string[] args, IDictionary environment, PaoPaths paths, Action<HostApplicationBuilder>? configure = null)
    {
        var builder = Host.CreateApplicationBuilder(new HostApplicationBuilderSettings { Args = args, ContentRootPath = paths.BaseDirectory });
        builder.Configuration.AddPaoConfiguration(paths.Config, environment);
        var settings = ConfigValidator.Validate(PaoConfiguration.Bind(builder.Configuration));
        builder.Services.AddSerilog(logger => LoggingSetup.Configure(logger, settings.Logging, "worker", paths.Home));
        builder.Services.AddPlatform(settings);
        builder.Services.AddMediator(typeof(ApiApplication).Assembly);
        builder.Services.AddAreas();
        builder.Services.AddBackgroundJobs(new MigrationFiles(paths.Migrations).ReadModuleLists().OutboxModules);
        configure?.Invoke(builder);
        return (builder.Build(), settings);
    }

    /// <summary>
    /// The worker's only HTTP server, on METRICS_ADDR: liveness for the container health
    /// check, metrics and, with APP_ENV=test, the hooks that read captured pushes (the worker
    /// sends them).
    /// </summary>
    public static WebApplication InternalServer(IHost host, PaoSettings settings, Action<Microsoft.AspNetCore.Hosting.IWebHostBuilder>? configure = null)
    {
        InternalHandler[] handlers = settings.App.Environment == AppEnvironments.Test
            ? [Infrastructure.Hosting.InternalServer.Liveness, Infrastructure.Hosting.InternalServer.Metrics, TestHooks.Handle]
            : [Infrastructure.Hosting.InternalServer.Liveness, Infrastructure.Hosting.InternalServer.Metrics];
        return Infrastructure.Hosting.InternalServer.Build(settings.Http.MetricsAddress, host.Services, configure, handlers);
    }
}
