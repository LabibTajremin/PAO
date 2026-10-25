using System.Collections.Concurrent;
using System.Globalization;
using System.Text.Json;
using System.Text.Json.Nodes;
using System.Text.RegularExpressions;

namespace PAO.Infrastructure.Http.OpenApi;

/// <summary>
/// Validates JSON against the JSON Schema 2020-12 keywords the contract uses (type, enum,
/// lengths, pattern, format, bounds, items, required, properties, additionalProperties,
/// $ref) and reports the first problem in Ajv's words (`body/phone must match pattern
/// "…"`), the text existing clients read in `details.reason`.
/// </summary>
public sealed class SchemaValidator(SpecDocument document)
{
    private readonly ConcurrentDictionary<string, Regex> patterns = new(StringComparer.Ordinal);

    /// <summary>Returns why `value` breaks `schema`, prefixed with `path`, or null when it conforms.</summary>
    public string? Validate(JsonNode? value, JsonNode? schema, string path)
    {
        if (document.Resolve(schema) is not JsonObject s)
        {
            return null;
        }
        return TypeError(value, s, path)
            ?? StringError(value, s, path)
            ?? NumberError(value, s, path)
            ?? ArrayError(value, s, path)
            ?? ObjectError(value, s, path)
            ?? EnumError(value, s, path);
    }

    /// <summary>The JSON Schema type name of `value`.</summary>
    public static string KindOf(JsonNode? value) => value?.GetValueKind() switch
    {
        null or JsonValueKind.Null => "null",
        JsonValueKind.String => "string",
        JsonValueKind.Number => "number",
        JsonValueKind.True or JsonValueKind.False => "boolean",
        JsonValueKind.Array => "array",
        _ => "object",
    };

    private static string? TypeError(JsonNode? value, JsonObject s, string path)
    {
        if (s["type"] is not { } type)
        {
            return null;
        }
        var allowed = type is JsonArray list ? list.Select(t => (string)t!).ToArray() : [(string)type!];
        var kind = KindOf(value);
        var ok = allowed.Any(t => t == kind || (t == "integer" && kind == "number" && IsInteger(value!)) || (t == "number" && kind == "number"));
        return ok ? null : $"{path} must be {string.Join(',', allowed)}";
    }

    private string? StringError(JsonNode? value, JsonObject s, string path)
    {
        if (KindOf(value) != "string")
        {
            return null;
        }
        var text = value!.GetValue<string>();
        var length = text.EnumerateRunes().Count();
        if (s["maxLength"] is { } max && length > (int)max)
        {
            return $"{path} must NOT have more than {(int)max} characters";
        }
        if (s["minLength"] is { } min && length < (int)min)
        {
            return $"{path} must NOT have fewer than {(int)min} characters";
        }
        if (s["pattern"] is { } pattern && !Pattern((string)pattern!).IsMatch(text))
        {
            return $"{path} must match pattern \"{(string)pattern!}\"";
        }
        return s["format"] is { } format && !Formats.IsValid((string)format!, text)
            ? $"{path} must match format \"{(string)format!}\""
            : null;
    }

    private static string? NumberError(JsonNode? value, JsonObject s, string path)
    {
        if (KindOf(value) != "number")
        {
            return null;
        }
        var number = value!.GetValue<double>();
        if (s["maximum"] is { } max && number > (double)max)
        {
            return $"{path} must be <= {Format((double)max)}";
        }
        return s["minimum"] is { } min && number < (double)min ? $"{path} must be >= {Format((double)min)}" : null;
    }

    private string? ArrayError(JsonNode? value, JsonObject s, string path)
    {
        if (value is not JsonArray array)
        {
            return null;
        }
        if (s["maxItems"] is { } max && array.Count > (int)max)
        {
            return $"{path} must NOT have more than {(int)max} items";
        }
        if (s["minItems"] is { } min && array.Count < (int)min)
        {
            return $"{path} must NOT have fewer than {(int)min} items";
        }
        return s["items"] is { } items
            ? array.Select((item, i) => Validate(item, items, $"{path}/{i}")).FirstOrDefault(e => e is not null)
            : null;
    }

    private string? ObjectError(JsonNode? value, JsonObject s, string path)
    {
        if (value is not JsonObject obj)
        {
            return null;
        }
        var missing = (s["required"] as JsonArray)?.Select(r => (string)r!).FirstOrDefault(r => !obj.ContainsKey(r));
        if (missing is not null)
        {
            return $"{path} must have required property '{missing}'";
        }
        var properties = s["properties"] as JsonObject;
        var extra = obj.Where(p => properties?.ContainsKey(p.Key) != true).ToList();
        if (s["additionalProperties"] is JsonValue flag && flag.GetValueKind() == JsonValueKind.False && extra.Count > 0)
        {
            return $"{path} must NOT have additional properties";
        }
        if (s["additionalProperties"] is JsonObject additional)
        {
            var error = extra.Select(p => Validate(p.Value, additional, $"{path}/{p.Key}")).FirstOrDefault(e => e is not null);
            if (error is not null)
            {
                return error;
            }
        }
        return properties?.Where(p => obj.ContainsKey(p.Key))
            .Select(p => Validate(obj[p.Key], p.Value, $"{path}/{p.Key}"))
            .FirstOrDefault(e => e is not null);
    }

    private static string? EnumError(JsonNode? value, JsonObject s, string path) =>
        s["enum"] is JsonArray options && !options.Any(o => JsonNode.DeepEquals(o, value))
            ? $"{path} must be equal to one of the allowed values"
            : null;

    private static bool IsInteger(JsonNode value) => Math.Abs(value.GetValue<double>() % 1) == 0;

    private static string Format(double n) => n.ToString(CultureInfo.InvariantCulture);

    private Regex Pattern(string pattern) => patterns.GetOrAdd(pattern, p => new Regex(p, RegexOptions.CultureInvariant));
}
