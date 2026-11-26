using Microsoft.AspNetCore.Http;
using Microsoft.Extensions.Logging;
using PAO.Infrastructure.Http.Errors;
using PAO.Infrastructure.Http.OpenApi;

namespace PAO.Infrastructure.Http.Edge;

/// <summary>A route served outside the contract, such as the health checks.</summary>
public sealed record NonSpecRoute(string Method, string Path);

/// <summary>
/// Matches each request to an operation of the contract and stores it on the request, so
/// authentication and authorisation run before the body is looked at. Unknown paths get
/// 404 and known paths with the wrong method 405, before any controller runs.
/// </summary>
public sealed class SpecMatchMiddleware(RequestDelegate next, SpecRoutes routes, IEnumerable<NonSpecRoute> nonSpec, ILogger<SpecMatchMiddleware> logger)
{
    private readonly NonSpecRoute[] own = [.. nonSpec];

    /// <summary>Runs the match.</summary>
    public async Task InvokeAsync(HttpContext context)
    {
        var path = context.Request.Path.Value ?? "/";
        var method = context.Request.Method;
        var edge = context.Edge();
        var mine = own.Where(r => r.Path == path).ToList();
        if (mine.Count > 0)
        {
            if (!mine.Any(r => r.Method == method))
            {
                await ErrorResponses.Write(context, ApiErrors.MethodNotAllowed, logger);
                return;
            }
            edge.RouteTemplate = path;
            await next(context);
            return;
        }
        var (match, miss) = routes.Match(method, path);
        if (match is null)
        {
            await ErrorResponses.Write(context, miss == RouteMiss.NotFound ? ApiErrors.NotFound : ApiErrors.MethodNotAllowed, logger);
            return;
        }
        edge.Operation = match;
        edge.RouteTemplate = match.Operation.PathTemplate;
        await next(context);
    }
}

/// <summary>The outermost guard: anything that escapes the pipeline is answered in the error envelope.</summary>
public sealed class ErrorEnvelopeMiddleware(RequestDelegate next, ILogger<ErrorEnvelopeMiddleware> logger)
{
    /// <summary>Runs the rest of the pipeline.</summary>
    public async Task InvokeAsync(HttpContext context)
    {
        try
        {
            await next(context);
        }
        catch (Exception error) when (!context.RequestAborted.IsCancellationRequested)
        {
            await ErrorResponses.Write(context, error, logger);
        }
    }
}
