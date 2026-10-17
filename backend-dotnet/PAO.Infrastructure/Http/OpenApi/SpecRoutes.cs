using System.Text.Json.Nodes;
using System.Text.RegularExpressions;

namespace PAO.Infrastructure.Http.OpenApi;

/// <summary>An OpenAPI parameter, after `$ref` resolution.</summary>
public sealed record SpecParameter(string Name, string In, bool Required, JsonNode? Schema);

/// <summary>One operation of the contract with everything needed to match and check requests.</summary>
public sealed record OperationInfo
{
    public required string Id { get; init; }
    public required string Method { get; init; }
    public required string PathTemplate { get; init; }

    /// <summary>The `x-permission`; null means the spec forgot it and requests are denied.</summary>
    public string? Permission { get; init; }

    /// <summary>True when the operation declares `security: []` (no token).</summary>
    public required bool Public { get; init; }

    /// <summary>True when the operation takes an `Idempotency-Key` header.</summary>
    public required bool Idempotent { get; init; }
    public required IReadOnlyList<SpecParameter> Parameters { get; init; }
    public JsonObject? RequestBody { get; init; }
}

/// <summary>An operation matched for a request, with its path parameters as sent.</summary>
public sealed record MatchedOperation(OperationInfo Operation, IReadOnlyDictionary<string, string> PathParameters);

/// <summary>Why a request matched no operation.</summary>
public enum RouteMiss
{
    NotFound,
    MethodNotAllowed,
}

/// <summary>
/// Matches requests to the operations of the contract. Literal paths win over templated
/// ones, so `/v1/admin/providers/queue` is never read as `/v1/admin/providers/{id}`.
/// </summary>
public sealed partial class SpecRoutes
{
    private static readonly string[] Methods = ["get", "put", "post", "delete", "patch", "options", "head", "trace"];
    private readonly List<PathEntry> entries = [];

    /// <summary>Indexes every operation of `document`.</summary>
    public SpecRoutes(SpecDocument document)
    {
        foreach (var (template, item) in document.Root["paths"]!.AsObject())
        {
            entries.Add(Entry(document, template, item!.AsObject()));
        }
        entries.Sort((a, b) => a.Names.Count.CompareTo(b.Names.Count));
    }

    /// <summary>Every operation of the contract.</summary>
    public IEnumerable<OperationInfo> Operations => entries.SelectMany(e => e.Operations.Values);

    /// <summary>Finds the operation for `method` and `path` (without the query string).</summary>
    public (MatchedOperation? Match, RouteMiss Miss) Match(string method, string path)
    {
        var miss = RouteMiss.NotFound;
        foreach (var e in entries)
        {
            var values = e.Pattern.Match(path);
            if (!values.Success)
            {
                continue;
            }
            if (!e.Operations.TryGetValue(method.ToLowerInvariant(), out var op))
            {
                miss = RouteMiss.MethodNotAllowed;
                continue;
            }
            var parameters = e.Names.Select((n, i) => KeyValuePair.Create(n, Uri.UnescapeDataString(values.Groups[i + 1].Value)));
            return (new MatchedOperation(op, new Dictionary<string, string>(parameters, StringComparer.Ordinal)), miss);
        }
        return (null, miss);
    }

    private static PathEntry Entry(SpecDocument document, string template, JsonObject item)
    {
        var names = new List<string>();
        var source = TemplatePart().Replace(Regex.Escape(template).Replace(@"\{", "{", StringComparison.Ordinal), m =>
        {
            names.Add(m.Groups[1].Value);
            return "([^/]+)";
        });
        var shared = item["parameters"]?.AsArray() ?? [];
        var operations = new Dictionary<string, OperationInfo>(StringComparer.Ordinal);
        foreach (var method in Methods.Where(m => item[m] is not null))
        {
            var op = item[method]!.AsObject();
            var parameters = shared.Concat(op["parameters"]?.AsArray() ?? [])
                .Select(p => document.Resolve(p)!.AsObject())
                .Select(p => new SpecParameter((string)p["name"]!, (string)p["in"]!, p["required"]?.GetValue<bool>() == true, p["schema"]))
                .ToList();
            var undeclared = names.FirstOrDefault(n => !parameters.Any(p => p.In == "path" && p.Name == n));
            if (undeclared is not null)
            {
                throw new InvalidDataException($"{method} {template}: path parameter {undeclared} is not declared");
            }
            operations[method] = new OperationInfo
            {
                Id = op["operationId"]?.GetValue<string>() ?? $"{method} {template}",
                Method = method,
                PathTemplate = template,
                Permission = op["x-permission"]?.GetValue<string>(),
                Public = op["security"] is JsonArray { Count: 0 },
                Idempotent = parameters.Any(p => p.In == "header" && p.Name == "Idempotency-Key"),
                Parameters = parameters,
                RequestBody = document.Resolve(op["requestBody"]) as JsonObject,
            };
        }
        return new PathEntry(new Regex($"^{source}$", RegexOptions.CultureInvariant), names, operations);
    }

    [GeneratedRegex(@"\{([^}]+)\}")]
    private static partial Regex TemplatePart();

    private sealed record PathEntry(Regex Pattern, IReadOnlyList<string> Names, IReadOnlyDictionary<string, OperationInfo> Operations);
}
