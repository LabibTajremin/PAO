// The worker process: the outbox relay and the periodic jobs, plus liveness and metrics on
// METRICS_ADDR; `worker healthcheck` is the container health check. Composition root
// (excluded from coverage; the start-up smoke tests run it).
using PAO.Infrastructure.Health;
using PAO.Infrastructure.Hosting;
using PAO.Worker;

if (args is ["healthcheck"])
{
    using var http = new HttpClient();
    return await HealthEndpoints.Probe(http, "http://127.0.0.1:9090/healthz", TimeSpan.FromSeconds(2)) ? 0 : 1;
}
try
{
    var (host, settings) = WorkerApplication.Build(args, Environment.GetEnvironmentVariables(), PaoPaths.Current());
    await PlatformServices.Prepare(host.Services, CancellationToken.None);
    await using var server = WorkerApplication.InternalServer(host, settings);
    await server.StartAsync();
    await host.RunAsync();
    await server.StopAsync();
    return 0;
}
catch (Exception error)
{
    await Console.Error.WriteLineAsync($"{{\"level\":\"ERROR\",\"msg\":\"worker stopped\",\"err\":{System.Text.Json.JsonSerializer.Serialize(error.Message)}}}");
    return 1;
}
