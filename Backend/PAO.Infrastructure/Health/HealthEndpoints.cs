using Microsoft.AspNetCore.Builder;
using Microsoft.AspNetCore.Http;
using Microsoft.AspNetCore.Routing;
using Microsoft.Extensions.DependencyInjection;
using PAO.Infrastructure.Http.Edge;

namespace PAO.Infrastructure.Health;

/// <summary>Checks that one dependency (database, Redis, storage) answers.</summary>
public sealed record HealthCheck(string Name, Func<CancellationToken, Task> Check);

/// <summary>Liveness and readiness for Docker and load balancers, served outside the contract.</summary>
public static class HealthEndpoints
{
    /// <summary>The health routes, for the spec matcher.</summary>
    public static readonly NonSpecRoute[] Routes = [new("GET", "/healthz"), new("GET", "/readyz")];

    /// <summary>Readiness: `{status: ok}`, or 503 naming every dependency that did not answer.</summary>
    public static async Task<(int Status, object Body)> Readiness(IEnumerable<HealthCheck> checks, CancellationToken cancellationToken)
    {
        var results = await Task.WhenAll(checks.Select(async c =>
        {
            try
            {
                await c.Check(cancellationToken);
                return (c.Name, Ok: true);
            }
            catch (Exception) when (!cancellationToken.IsCancellationRequested)
            {
                return (c.Name, Ok: false);
            }
        }));
        var failed = results.Where(r => !r.Ok).ToDictionary(r => r.Name, _ => "unavailable");
        return failed.Count == 0
            ? (200, new { status = "ok" })
            : (503, new { checks = failed, status = "unavailable" });
    }

    /// <summary>Maps GET /healthz (200 while the process serves HTTP) and GET /readyz.</summary>
    public static void MapHealth(this IEndpointRouteBuilder endpoints)
    {
        endpoints.MapGet("/healthz", () => Results.Json(new { status = "ok" }));
        endpoints.MapGet("/readyz", async (HttpContext context) =>
        {
            var (status, body) = await Readiness(context.RequestServices.GetServices<HealthCheck>(), context.RequestAborted);
            return Results.Json(body, statusCode: status);
        });
    }

    /// <summary>
    /// The container health check: true only when `url` answers 200 within `timeout`. The
    /// image runs `/app/api healthcheck` instead of shipping curl.
    /// </summary>
    public static async Task<bool> Probe(HttpClient http, string url, TimeSpan timeout)
    {
        using var cancel = new CancellationTokenSource(timeout);
        try
        {
            using var response = await http.GetAsync(url, cancel.Token);
            return response.StatusCode == System.Net.HttpStatusCode.OK;
        }
        catch (Exception e) when (e is HttpRequestException or OperationCanceledException)
        {
            return false;
        }
    }
}
