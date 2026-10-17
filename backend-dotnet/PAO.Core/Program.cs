// The API process: serves the contract on HTTP_ADDR and metrics on METRICS_ADDR;
// `api healthcheck` is the container health check. Composition root (excluded from
// coverage; the start-up smoke tests run it).
using PAO.Core;
using PAO.Infrastructure.Health;
using PAO.Infrastructure.Hosting;

if (args is ["healthcheck"])
{
    using var http = new HttpClient();
    return await HealthEndpoints.Probe(http, "http://127.0.0.1:8080/healthz", TimeSpan.FromSeconds(2)) ? 0 : 1;
}
try
{
    var (app, settings) = ApiApplication.Build(args, Environment.GetEnvironmentVariables(), PaoPaths.Current());
    await PlatformServices.Prepare(app.Services, CancellationToken.None);
    await using var metrics = ApiApplication.MetricsServer(app, settings);
    await metrics.StartAsync();
    await app.RunAsync();
    await metrics.StopAsync();
    return 0;
}
catch (Exception error)
{
    await Console.Error.WriteLineAsync($"{{\"level\":\"ERROR\",\"msg\":\"api stopped\",\"err\":{System.Text.Json.JsonSerializer.Serialize(error.Message)}}}");
    return 1;
}
