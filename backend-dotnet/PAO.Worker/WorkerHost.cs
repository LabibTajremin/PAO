using PAO.Infrastructure.Configuration;
using PAO.Infrastructure.Health;
using PAO.Infrastructure.Hosting;
using PAO.Infrastructure.Registration;
using PAO.Infrastructure.Testing;

namespace PAO.Worker;

/// <summary>
/// Runs the built worker: start-up checks, the internal server on METRICS_ADDR (liveness,
/// metrics and, with APP_ENV=test, the hooks that read captured pushes), then the relay
/// and jobs until shutdown.
/// </summary>
public static class WorkerHost
{
    /// <summary>The URL the container health check probes.</summary>
    public const string HealthUrl = "http://127.0.0.1:9090/healthz";

    /// <summary>Checks the platform, starts the internal server and runs until the host stops.</summary>
    public static async Task<int> RunWorker(this IHost host, PaoSettings settings, Action<IWebHostBuilder>? configureServer = null)
    {
        await host.Services.Prepare(CancellationToken.None);
        await using var server = InternalServer.Build(settings.Http.MetricsAddress, host.Services, configureServer, Handlers(settings));
        await server.StartAsync();
        await host.RunAsync();
        await server.StopAsync();
        return 0;
    }

    /// <summary>The internal server's handlers; the test hooks only when APP_ENV=test.</summary>
    public static InternalHandler[] Handlers(PaoSettings settings) => settings.App.Environment == AppEnvironments.Test
        ? [InternalServer.Liveness, InternalServer.Metrics, TestHooks.Handle]
        : [InternalServer.Liveness, InternalServer.Metrics];

    /// <summary>The container health check: 0 when the local worker answers /healthz with 200.</summary>
    public static async Task<int> HealthCheck(HttpMessageHandler? handler = null, string url = HealthUrl)
    {
        using var http = handler is null ? new HttpClient() : new HttpClient(handler);
        return await HealthEndpoints.Probe(http, url, TimeSpan.FromSeconds(2)) ? 0 : 1;
    }
}
