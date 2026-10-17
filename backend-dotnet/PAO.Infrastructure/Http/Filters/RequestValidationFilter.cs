using Microsoft.AspNetCore.Http;
using Microsoft.AspNetCore.Mvc.Filters;
using PAO.Infrastructure.Http.Edge;
using PAO.Infrastructure.Http.Errors;
using PAO.Infrastructure.Http.OpenApi;

namespace PAO.Infrastructure.Http.Filters;

/// <summary>
/// Rejects requests that break the contract with 422 VALIDATION_FAILED, `details.reason`
/// saying why, before the handler runs. It runs before idempotency, so an invalid request
/// never claims an idempotency key, as in NestJS.
/// </summary>
public sealed class RequestValidationFilter(RequestValidator validator) : IAsyncActionFilter, IOrderedFilter
{
    /// <inheritdoc />
    public int Order => FilterOrder.Validation;

    /// <inheritdoc />
    public async Task OnActionExecutionAsync(ActionExecutingContext context, ActionExecutionDelegate next)
    {
        var edge = context.HttpContext.Edge();
        if (edge.Operation is { } match)
        {
            var reason = validator.Check(match.Operation, Parts(context.HttpContext.Request, edge, match));
            if (reason is not null)
            {
                throw ApiErrors.Validation("reason", reason);
            }
        }
        await next();
    }

    private static RequestParts Parts(HttpRequest request, EdgeState edge, MatchedOperation match) => new()
    {
        Path = match.PathParameters,
        Query = request.Query.ToDictionary(q => q.Key, q => q.Value.Select(v => v ?? string.Empty).ToArray(), StringComparer.Ordinal),
        Headers = request.Headers.ToDictionary(h => h.Key.ToLowerInvariant(), h => h.Value.Select(v => v ?? string.Empty).ToArray(), StringComparer.Ordinal),
        Cookies = request.Cookies.ToDictionary(c => c.Key, c => new[] { c.Value }, StringComparer.Ordinal),
        ContentType = request.ContentType,
        RawBody = edge.RawBody,
        BodyError = edge.BodyError,
        Body = edge.Body,
    };
}
