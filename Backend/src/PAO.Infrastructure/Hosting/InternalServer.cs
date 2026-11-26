using Microsoft.AspNetCore.Builder;
using Microsoft.AspNetCore.Hosting;
using Microsoft.AspNetCore.Http;
using Microsoft.Extensions.DependencyInjection;
using Microsoft.Extensions.Logging;
using PAO.Infrastructure.Metrics;

namespace PAO.Infrastructure.Hosting;

/// <summary>Answers a request on the internal server and reports whether it did, so handlers chain.</summary>
public delegate Task<bool> InternalHandler(HttpContext context);

/// <summary>
/// The small HTTP server on METRICS_ADDR (never exposed publicly): metrics for both hosts,
/// plus liveness and, with APP_ENV=test, the test hooks for the worker.
/// </summary>
public static class InternalServer
{
    /// <summary>Builds the server on `address`; handlers resolve services from `hostServices`.</summary>
    public static WebApplication Build(string address, IServiceProvider hostServices, Action<IWebHostBuilder>? configure, params InternalHandler[] handlers)
    {
        var builder = WebApplication.CreateSlimBuilder();
        builder.Logging.ClearProviders();
        builder.WebHost.UseUrls(ListenAddress.Parse(address).ToUrl());
        configure?.Invoke(builder.WebHost);
        var app = builder.Build();
        app.Run(async context =>
        {
            context.RequestServices = hostServices;
            foreach (var handle in handlers)
            {
                if (await handle(context))
                {
                    return;
                }
            }
            context.Response.StatusCode = 404;
            await context.Response.WriteAsync("404 page not found\n");
        });
        return app;
    }

    /// <summary>Serves the registry on GET /metrics.</summary>
    public static async Task<bool> Metrics(HttpContext context)
    {
        if (!IsGet(context, "/metrics"))
        {
            return false;
        }
        await context.RequestServices.GetRequiredService<PaoMetrics>().Render(context);
        return true;
    }

    /// <summary>Answers GET /healthz with 200 while the process can serve HTTP at all.</summary>
    public static async Task<bool> Liveness(HttpContext context)
    {
        if (!IsGet(context, "/healthz"))
        {
            return false;
        }
        context.Response.ContentType = "application/json";
        await context.Response.WriteAsync("{\"status\":\"ok\"}\n");
        return true;
    }

    private static bool IsGet(HttpContext context, string path) =>
        HttpMethods.IsGet(context.Request.Method) && context.Request.Path == path;
}
