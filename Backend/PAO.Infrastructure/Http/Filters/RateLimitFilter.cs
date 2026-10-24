using Microsoft.AspNetCore.Mvc.Filters;
using Microsoft.Extensions.Options;
using PAO.Infrastructure.Configuration;
using PAO.Infrastructure.Http.Edge;
using PAO.Infrastructure.Http.Errors;
using PAO.Infrastructure.Redis;

namespace PAO.Infrastructure.Http.Filters;

/// <summary>
/// Applies the API rate limit to every spec operation, per signed-in user or per IP for
/// anonymous calls (`rl:api:{subject}:{operationId}`); 120 and 60 calls a minute by default.
/// </summary>
public sealed class RateLimitFilter(RateLimiter limiter, RedisKeys keys, IOptions<HttpOptions> options) : IAsyncActionFilter
{
    /// <inheritdoc />
    public async Task OnActionExecutionAsync(ActionExecutingContext context, ActionExecutionDelegate next)
    {
        var edge = context.HttpContext.Edge();
        if (edge.Operation is { } match)
        {
            var http = options.Value;
            var (subject, limit) = edge.Principal is { } principal
                ? ($"user:{principal.AccountId}", http.RateLimitPerUser)
                : ($"ip:{edge.ClientIp}", http.RateLimitPerIp);
            var key = keys.Key("rl", "api", subject, match.Operation.Id);
            var decision = await limiter.Allow(key, limit, TimeSpan.FromSeconds(http.RateLimitWindowSeconds));
            if (!decision.Allowed)
            {
                throw ApiErrors.RateLimited("RATE_LIMITED", decision.RetryAfter);
            }
        }
        await next();
    }
}
