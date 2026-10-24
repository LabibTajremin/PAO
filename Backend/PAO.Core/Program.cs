// The API process: serves the contract on HTTP_ADDR and metrics on METRICS_ADDR;
// `api healthcheck` is the container health check. Composition root: it only calls the
// named registration methods (excluded from coverage; the start-up smoke tests run it).
using PAO.Core;
using PAO.Core.Registration;
using PAO.Infrastructure.Hosting;
using PAO.Infrastructure.Http;
using PAO.Infrastructure.Registration;

if (args is ["healthcheck"])
{
    return await ApiHost.HealthCheck();
}
try
{
    var builder = WebApplication.CreateBuilder(new WebApplicationOptions { Args = args, ContentRootPath = AppContext.BaseDirectory });
    var paths = PaoPaths.Current();
    var settings = builder.AddPaoSettings(paths, Environment.GetEnvironmentVariables(), "api");
    builder.Services
        .AddBuiltInServices(settings, paths.Spec, typeof(ApiHost).Assembly)
        .AddCustomServices(settings, typeof(ApiHost).Assembly)
        .AddDatabase(settings)
        .AddRepositories()
        .AddAreas();
    var app = builder.Build();
    app.UseHttpEdge(settings);
    return await app.RunApi(settings);
}
catch (Exception error)
{
    await Console.Error.WriteLineAsync($"{{\"level\":\"ERROR\",\"msg\":\"api stopped\",\"err\":{System.Text.Json.JsonSerializer.Serialize(error.Message)}}}");
    return 1;
}
