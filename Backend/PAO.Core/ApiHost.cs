using PAO.Infrastructure.Configuration;
using PAO.Infrastructure.Health;
using PAO.Infrastructure.Hosting;
using PAO.Infrastructure.Registration;

namespace PAO.Core;

/// <summary>Runs the built API: start-up checks, the metrics server on METRICS_ADDR, then the API until shutdown.</summary>
public static class ApiHost
{
    /// <summary>The URL the container health check probes.</summary>
    public const string HealthUrl = "http://127.0.0.1:8080/healthz";

    /// <summary>
    /// Checks the platform, starts the metrics server and serves until the host stops;
    /// `configureMetrics` lets tests swap the metrics server's transport.
    /// </summary>
    public static async Task<int> RunApi(this WebApplication app, PaoSettings settings, Action<IWebHostBuilder>? configureMetrics = null)
    {
        await app.Services.Prepare(CancellationToken.None);
        await using var metrics = InternalServer.Build(settings.Http.MetricsAddress, app.Services, configureMetrics, InternalServer.Metrics);
        await metrics.StartAsync();
        await app.RunAsync();
        await metrics.StopAsync();
        return 0;
    }

    /// <summary>The container health check: 0 when the local API answers /healthz with 200.</summary>
    public static async Task<int> HealthCheck(HttpMessageHandler? handler = null, string url = HealthUrl)
    {
        using var http = handler is null ? new HttpClient() : new HttpClient(handler);
        return await HealthEndpoints.Probe(http, url, TimeSpan.FromSeconds(2)) ? 0 : 1;
    }
}
