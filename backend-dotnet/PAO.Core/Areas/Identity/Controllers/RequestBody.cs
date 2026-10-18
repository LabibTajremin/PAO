using System.Text.Json;
using PAO.Infrastructure.Http.Edge;

namespace PAO.Core.Areas.Identity.Controllers;

/// <summary>
/// Reads the JSON body the edge already parsed and the spec validated. MVC's body binding
/// would answer 415 to a request without a body before authorisation runs, where NestJS
/// answered 401 or 403 first.
/// </summary>
public static class RequestBody
{
    /// <summary>The body as `T`; an absent body is an empty `T`.</summary>
    public static T Read<T>(HttpContext context)
        where T : class, new() =>
        context.Edge().Body is { } body ? body.Deserialize<T>(JsonSerializerOptions.Web) ?? new T() : new T();
}
