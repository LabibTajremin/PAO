// The worker process: the outbox relay and the periodic jobs, plus liveness and metrics on
// METRICS_ADDR; `worker healthcheck` is the container health check. Composition root: it
// only calls the named registration methods (excluded from coverage; the start-up smoke
// tests run it).
using PAO.BackgroundJobs;
using PAO.Core;
using PAO.Core.Registration;
using PAO.Infrastructure.Hosting;
using PAO.Infrastructure.Registration;
using PAO.Worker;

if (args is ["healthcheck"])
{
    return await WorkerHost.HealthCheck();
}
try
{
    var builder = Host.CreateApplicationBuilder(new HostApplicationBuilderSettings { Args = args, ContentRootPath = AppContext.BaseDirectory });
    var paths = PaoPaths.Current();
    var settings = builder.AddPaoSettings(paths, Environment.GetEnvironmentVariables(), "worker");
    builder.Services
        .AddBuiltInServices(settings)
        .AddCustomServices(settings, typeof(ApiHost).Assembly)
        .AddDatabase(settings)
        .AddRepositories()
        .AddAreas()
        .AddBackgroundJobs(paths);
    return await builder.Build().RunWorker(settings);
}
catch (Exception error)
{
    await Console.Error.WriteLineAsync($"{{\"level\":\"ERROR\",\"msg\":\"worker stopped\",\"err\":{System.Text.Json.JsonSerializer.Serialize(error.Message)}}}");
    return 1;
}
