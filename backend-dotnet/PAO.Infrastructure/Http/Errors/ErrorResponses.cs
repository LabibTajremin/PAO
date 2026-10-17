using System.Text.Json;
using Microsoft.AspNetCore.Http;
using Microsoft.Extensions.Logging;
using PAO.Lib.Errors;

namespace PAO.Infrastructure.Http.Errors;

/// <summary>
/// Writes every error in the single PRD §9.6 envelope, `{"error":{"code","message","details?"}}`,
/// with Retry-After on 429. Server errors are logged with their cause; the cause never
/// reaches the client.
/// </summary>
public static class ErrorResponses
{
    private static readonly JsonSerializerOptions Json = new() { Encoder = System.Text.Encodings.Web.JavaScriptEncoder.UnsafeRelaxedJsonEscaping };

    // ASP.NET raises BadHttpRequestException for a few framework-level failures.
    private static readonly Dictionary<int, ApiError> FrameworkErrors = new()
    {
        [400] = ApiErrors.ValidationFailed,
        [401] = ApiErrors.Unauthenticated,
        [403] = ApiErrors.Forbidden,
        [404] = ApiErrors.NotFound,
        [413] = ApiErrors.ValidationFailed,
        [422] = ApiErrors.ValidationFailed,
    };

    /// <summary>The API error to send for `error`; anything unexpected becomes 500 INTERNAL.</summary>
    public static ApiError ToApiError(Exception error) => error switch
    {
        ApiError api => api,
        BadHttpRequestException bad => FrameworkErrors.GetValueOrDefault(bad.StatusCode, ApiErrors.Internal).Wrap(bad),
        _ => ApiErrors.Internal.Wrap(error),
    };

    /// <summary>The envelope for `error`.</summary>
    public static Dictionary<string, object> Body(ApiError error)
    {
        var body = new Dictionary<string, object> { ["code"] = error.Code, ["message"] = error.Message };
        if (error.Details is { Count: > 0 } details)
        {
            body["details"] = details;
        }
        return new Dictionary<string, object> { ["error"] = body };
    }

    /// <summary>Writes `error` to the response, or logs it when the response already started.</summary>
    public static async Task Write(HttpContext context, Exception error, ILogger logger)
    {
        var response = context.Response;
        if (response.HasStarted)
        {
            logger.LogError(error, "error after the response started {Path}", context.Request.Path.Value);
            return;
        }
        if (error is StoredResponseException stored)
        {
            response.StatusCode = stored.Status;
            response.ContentType = "application/json";
            response.Headers["Idempotent-Replayed"] = "true";
            await response.Body.WriteAsync(stored.Body);
            return;
        }
        var api = ToApiError(error);
        if (api.Status >= 500)
        {
            logger.LogError(api.InnerException ?? api, "unhandled error {Path}", context.Request.Path.Value);
        }
        if (api.RetryAfter > TimeSpan.Zero)
        {
            response.Headers.RetryAfter = ((long)api.RetryAfter.TotalSeconds).ToString(System.Globalization.CultureInfo.InvariantCulture);
        }
        response.StatusCode = api.Status;
        response.ContentType = "application/json";
        await response.WriteAsync(JsonSerializer.Serialize(Body(api), Json) + "\n");
    }
}

/// <summary>An area's mapping from <see cref="DomainException"/> reasons to API errors.</summary>
public interface IErrorMap
{
    /// <summary>Reason → API error.</summary>
    IReadOnlyDictionary<string, ApiError> Errors { get; }
}

/// <summary>Applies an <see cref="IErrorMap"/> to what a controller throws: `[ErrorMap(typeof(BookingErrorMap))]`.</summary>
[AttributeUsage(AttributeTargets.Class | AttributeTargets.Method, AllowMultiple = false)]
public sealed class ErrorMapAttribute(Type mapType) : Attribute
{
    /// <summary>The map, created once per attribute.</summary>
    public IErrorMap Map { get; } = (IErrorMap)Activator.CreateInstance(mapType)!;

    /// <summary>The API error for `error` (a domain error, possibly as a cause), or `error` unchanged.</summary>
    public Exception Apply(Exception error)
    {
        for (var e = error; e is not null; e = e.InnerException)
        {
            if (e is DomainException domain && Map.Errors.TryGetValue(domain.Reason, out var api))
            {
                return api.Wrap(error);
            }
        }
        return error;
    }
}
