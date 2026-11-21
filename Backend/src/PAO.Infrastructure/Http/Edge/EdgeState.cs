using System.Text.Json.Nodes;
using Microsoft.AspNetCore.Http;
using PAO.Infrastructure.Http.Authorization;
using PAO.Infrastructure.Http.OpenApi;

namespace PAO.Infrastructure.Http.Edge;

/// <summary>What the HTTP edge learns about a request on its way to the controller.</summary>
public sealed class EdgeState
{
    /// <summary>The caller's address, after trusting our load balancer's X-Forwarded-For.</summary>
    public string ClientIp { get; set; } = string.Empty;

    /// <summary>The body as received, at most the body limit; idempotency fingerprints it.</summary>
    public byte[] RawBody { get; set; } = [];

    /// <summary>Why the body could not be read or parsed; reported by request validation.</summary>
    public string? BodyError { get; set; }

    /// <summary>The body parsed as JSON, when it is JSON.</summary>
    public JsonNode? Body { get; set; }

    /// <summary>The route template the request matched, for metrics (`/v1/bookings/{id}`).</summary>
    public string? RouteTemplate { get; set; }

    /// <summary>The contract operation the request matched, if it is a spec route.</summary>
    public MatchedOperation? Operation { get; set; }

    /// <summary>The authenticated caller.</summary>
    public Principal? Principal { get; set; }
}

/// <summary>Reads and creates the <see cref="EdgeState"/> of a request.</summary>
public static class EdgeStateExtensions
{
    private static readonly object Key = new();

    /// <summary>The request's edge state, created on first use.</summary>
    public static EdgeState Edge(this HttpContext context)
    {
        if (context.Items[Key] is not EdgeState state)
        {
            state = new EdgeState();
            context.Items[Key] = state;
        }
        return state;
    }
}
