using System.Collections;
using PAO.Core.Areas;
using PAO.Infrastructure.Configuration;
using PAO.Infrastructure.Hosting;
using PAO.Infrastructure.Http;
using PAO.Infrastructure.Logging;
using PAO.Infrastructure.Mediation;
using Serilog;

namespace PAO.Core;

/// <summary>
/// Builds the API host: configuration from `Config/*.json` and the environment, Serilog,
/// the platform, the HTTP edge and every area. Program.cs only runs what this builds, so
/// tests build the same application.
/// </summary>
public static class ApiApplication
{
    /// <summary>Builds the app; `configure` lets tests swap the server or services before it is built.</summary>
    public static (WebApplication App, PaoSettings Settings) Build(
        string[] args, IDictionary environment, PaoPaths paths, Action<WebApplicationBuilder>? configure = null)
    {
        var builder = WebApplication.CreateBuilder(new WebApplicationOptions { Args = args, ContentRootPath = paths.BaseDirectory });
        builder.Configuration.AddPaoConfiguration(paths.Config, environment);
        var settings = ConfigValidator.Validate(PaoConfiguration.Bind(builder.Configuration));
        builder.Services.AddSerilog(logger => LoggingSetup.Configure(logger, settings.Logging, "api", paths.Home));
        builder.WebHost.UseUrls(ListenAddress.Parse(settings.Http.Address).ToUrl());
        builder.Services.AddPlatform(settings);
        builder.Services.AddHttpEdge(paths.Spec).AddApplicationPart(typeof(ApiApplication).Assembly);
        builder.Services.AddMediator(typeof(ApiApplication).Assembly);
        builder.Services.AddAreas();
        configure?.Invoke(builder);
        var app = builder.Build();
        app.UseHttpEdge(settings);
        return (app, settings);
    }

    /// <summary>The API's internal server on METRICS_ADDR: Prometheus metrics only.</summary>
    public static WebApplication MetricsServer(WebApplication app, PaoSettings settings, Action<IWebHostBuilder>? configure = null) =>
        InternalServer.Build(settings.Http.MetricsAddress, app.Services, configure, InternalServer.Metrics);
}
