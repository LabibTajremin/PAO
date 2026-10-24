using System.Text.Json;
using System.Text.Json.Nodes;
using System.Text.RegularExpressions;
using Microsoft.AspNetCore.Http;
using Serilog.Context;

namespace PAO.Infrastructure.Http.Edge;

/// <summary>
/// The middleware every request passes before routing, in the NestJS order: client IP,
/// request id, security headers, CORS, body reading.
/// </summary>
public static partial class EdgeMiddleware
{
    /// <summary>Stores the client address on the request.</summary>
    public static Task ClientAddress(HttpContext context, RequestDelegate next)
    {
        var peer = ClientIp.Normalize(context.Connection.RemoteIpAddress);
        context.Edge().ClientIp = ClientIp.Resolve(peer, [.. context.Request.Headers["X-Forwarded-For"].Select(v => v ?? string.Empty)]);
        return next(context);
    }

    /// <summary>Propagates a well-formed X-Request-ID or issues one, and logs every line with it.</summary>
    public static async Task RequestId(HttpContext context, RequestDelegate next)
    {
        var sent = context.Request.Headers["X-Request-ID"].ToString();
        var id = RequestIdText().IsMatch(sent) ? sent : Guid.NewGuid().ToString();
        context.Response.Headers["X-Request-ID"] = id;
        using (LogContext.PushProperty("request_id", id))
        {
            await next(context);
        }
    }

    /// <summary>Sets the security headers of 02-architecture §7 on every response.</summary>
    public static Task SecurityHeaders(HttpContext context, RequestDelegate next)
    {
        var headers = context.Response.Headers;
        headers.XContentTypeOptions = "nosniff";
        headers.XFrameOptions = "DENY";
        headers["Referrer-Policy"] = "no-referrer";
        headers.ContentSecurityPolicy = "default-src 'none'; frame-ancestors 'none'";
        headers.StrictTransportSecurity = "max-age=31536000; includeSubDomains";
        return next(context);
    }

    /// <summary>Allows only the admin web origin, with credentials for its refresh cookie.</summary>
    public static Func<HttpContext, RequestDelegate, Task> Cors(string origin) => (context, next) =>
    {
        var request = context.Request;
        if (request.Headers.Origin == origin)
        {
            var headers = context.Response.Headers;
            headers.AccessControlAllowOrigin = origin;
            headers.AccessControlAllowCredentials = "true";
            headers.AccessControlAllowMethods = "GET, POST, PUT, PATCH, DELETE, OPTIONS";
            headers.AccessControlAllowHeaders = "Authorization, Content-Type, Idempotency-Key, X-Request-ID";
            headers.AccessControlMaxAge = "600";
            headers.Append("Vary", "Origin");
        }
        if (HttpMethods.IsOptions(request.Method) && request.Headers.ContainsKey("Access-Control-Request-Method"))
        {
            context.Response.StatusCode = StatusCodes.Status204NoContent;
            return Task.CompletedTask;
        }
        return next(context);
    };

    /// <summary>
    /// Reads the body (at most `maxBytes`) and parses JSON. Problems are recorded, not
    /// answered, because request validation reports them after authentication.
    /// </summary>
    public static Func<HttpContext, RequestDelegate, Task> ReadBody(int maxBytes) => async (context, next) =>
    {
        var edge = context.Edge();
        try
        {
            var raw = await ReadAtMost(context.Request.Body, maxBytes, context.RequestAborted);
            if (raw is null)
            {
                edge.BodyError = "request body too large";
            }
            else
            {
                edge.RawBody = raw;
                edge.Body = ParseJson(edge, context.Request.ContentType);
            }
        }
        catch (IOException)
        {
            edge.BodyError = "request body could not be read";
        }
        context.Request.Body = new MemoryStream(edge.RawBody, writable: false);
        await next(context);
    };

    // Null when the body is longer than `maxBytes`.
    private static async Task<byte[]?> ReadAtMost(Stream body, int maxBytes, CancellationToken cancellationToken)
    {
        using var copy = new MemoryStream();
        var chunk = new byte[16 * 1024];
        int read;
        while ((read = await body.ReadAsync(chunk, cancellationToken)) > 0)
        {
            if (copy.Length + read > maxBytes)
            {
                return null;
            }
            copy.Write(chunk, 0, read);
        }
        return copy.ToArray();
    }

    private static JsonNode? ParseJson(EdgeState edge, string? contentType)
    {
        if (edge.RawBody.Length == 0)
        {
            return null;
        }
        try
        {
            return JsonNode.Parse(edge.RawBody);
        }
        catch (JsonException)
        {
            if (JsonContentType().IsMatch(contentType ?? string.Empty))
            {
                edge.BodyError = "request body is not valid JSON";
            }
            return null;
        }
    }

    [GeneratedRegex("^[A-Za-z0-9._-]{8,64}$")]
    private static partial Regex RequestIdText();

    [GeneratedRegex(@"^application/json\b", RegexOptions.IgnoreCase)]
    private static partial Regex JsonContentType();
}
