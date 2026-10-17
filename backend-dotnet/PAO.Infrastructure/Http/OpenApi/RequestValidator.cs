using System.Collections.Concurrent;
using System.Globalization;
using System.Text.Json;
using System.Text.Json.Nodes;
using System.Text.RegularExpressions;

namespace PAO.Infrastructure.Http.OpenApi;

/// <summary>The parts of a request the contract constrains.</summary>
public sealed record RequestParts
{
    public required IReadOnlyDictionary<string, string> Path { get; init; }
    public required IReadOnlyDictionary<string, string[]> Query { get; init; }

    /// <summary>Header names in lower case.</summary>
    public required IReadOnlyDictionary<string, string[]> Headers { get; init; }
    public required IReadOnlyDictionary<string, string[]> Cookies { get; init; }
    public string? ContentType { get; init; }
    public byte[]? RawBody { get; init; }
    public string? BodyError { get; init; }
    public JsonNode? Body { get; init; }
}

/// <summary>
/// Checks requests against the contract (PRD §9.6): path, query, header and cookie
/// parameters are coerced from strings to their schema types first; bodies are checked as
/// sent. Validators are prepared on first use per operation.
/// </summary>
public sealed partial class RequestValidator(SpecDocument document)
{
    private static readonly (string In, string Part)[] Locations = [("path", "path"), ("query", "query"), ("header", "headers"), ("cookie", "cookies")];
    private readonly SchemaValidator schemas = new(document);
    private readonly ConcurrentDictionary<OperationInfo, JsonObject[]> parameterSchemas = new();

    /// <summary>Returns why the request breaks the contract of `operation`, or null when it conforms.</summary>
    public string? Check(OperationInfo operation, RequestParts request)
    {
        var compiled = parameterSchemas.GetOrAdd(operation, op => [.. Locations.Select(l => ParameterSchema(op, l.In))]);
        for (var i = 0; i < Locations.Length; i++)
        {
            var values = Locations[i].In switch
            {
                "path" => request.Path.ToDictionary(p => p.Key, p => new[] { p.Value }),
                "query" => request.Query,
                "header" => request.Headers,
                _ => request.Cookies,
            };
            var error = schemas.Validate(Coerce(values, compiled[i]), compiled[i], Locations[i].Part);
            if (error is not null)
            {
                return error;
            }
        }
        return CheckBody(operation, request);
    }

    private string? CheckBody(OperationInfo operation, RequestParts request)
    {
        if (operation.RequestBody?["content"]?["application/json"] is not JsonObject json)
        {
            return null;
        }
        if (request.BodyError is not null)
        {
            return $"request body has an error: {request.BodyError}";
        }
        if (request.RawBody is not { Length: > 0 })
        {
            return operation.RequestBody["required"]?.GetValue<bool>() == true
                ? "request body has an error: value is required but missing"
                : null;
        }
        if (!JsonContentType().IsMatch(request.ContentType ?? string.Empty))
        {
            return $"header Content-Type has unexpected value: {JsonSerializer.Serialize(request.ContentType ?? string.Empty)}";
        }
        return schemas.Validate(request.Body, json["schema"], "body");
    }

    private JsonObject ParameterSchema(OperationInfo operation, string location)
    {
        var own = operation.Parameters.Where(p => p.In == location).ToList();
        string Key(SpecParameter p) => location == "header" ? p.Name.ToLowerInvariant() : p.Name;
        return new JsonObject
        {
            ["type"] = "object",
            ["properties"] = new JsonObject(own.Select(p => KeyValuePair.Create(Key(p), document.Resolve(p.Schema)?.DeepClone()))),
            ["required"] = new JsonArray([.. own.Where(p => p.Required).Select(p => (JsonNode)JsonValue.Create(Key(p))!)]),
        };
    }

    // Ajv's coerceTypes "array": strings become the scalar type the schema asks for, and a
    // single value becomes an array when the schema wants one.
    private JsonObject Coerce(IReadOnlyDictionary<string, string[]> values, JsonObject schema)
    {
        var result = new JsonObject();
        var properties = (JsonObject)schema["properties"]!;
        foreach (var (name, raw) in values)
        {
            if (properties[name] is not JsonObject property)
            {
                continue;
            }
            var type = (string?)document.Resolve(property)?["type"];
            result[name] = type == "array"
                ? new JsonArray([.. raw.Select(v => CoerceScalar(v, (string?)document.Resolve(property["items"])?["type"]))])
                : raw.Length == 1 ? CoerceScalar(raw[0], type) : new JsonArray([.. raw.Select(v => (JsonNode)JsonValue.Create(v)!)]);
        }
        return result;
    }

    private static JsonNode? CoerceScalar(string value, string? type) => type switch
    {
        "integer" or "number" when double.TryParse(value, NumberStyles.Float, CultureInfo.InvariantCulture, out var n) && double.IsFinite(n) =>
            JsonNode.Parse(n.ToString("R", CultureInfo.InvariantCulture)),
        "boolean" when value is "true" or "false" => JsonValue.Create(value == "true"),
        _ => JsonValue.Create(value),
    };

    [GeneratedRegex(@"^application/json\b", RegexOptions.IgnoreCase)]
    private static partial Regex JsonContentType();
}
