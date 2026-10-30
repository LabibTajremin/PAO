using System.Globalization;
using System.Text.Json.Nodes;

namespace PAO.E2ETests.Support;

/// <summary>Narrows decoded API JSON, failing loudly when the API sent another shape.</summary>
public static class Json
{
    public static JsonObject Obj(JsonNode? value) =>
        value as JsonObject ?? throw new InvalidOperationException($"want an object, got {Show(value)}");

    public static IReadOnlyList<JsonObject> List(JsonNode? value) =>
        value is JsonArray array ? array.Select(Obj).ToList() : throw new InvalidOperationException($"want an array, got {Show(value)}");

    public static string Str(JsonNode? value) =>
        value is JsonValue v && v.TryGetValue<string>(out var s) ? s : throw new InvalidOperationException($"want a string, got {Show(value)}");

    public static long Num(JsonNode? value) =>
        value is JsonValue v && v.TryGetValue<decimal>(out var d) ? (long)d : throw new InvalidOperationException($"want a number, got {Show(value)}");

    public static string Show(JsonNode? value) => value?.ToJsonString() ?? "null";

    /// <summary>Whether a field is absent or JSON null (contact details hidden before acceptance).</summary>
    public static bool Missing(JsonNode? value) => value is null;

    /// <summary>Asserts every listed field has the wanted value, like Jest's toMatchObject.</summary>
    public static void Has(JsonNode? node, params (string Key, object? Want)[] fields)
    {
        var o = Obj(node);
        foreach (var (key, want) in fields)
        {
            Assert.True(Same(o[key], want), $"{key}: want {want}, got {Show(o[key])} in {o.ToJsonString()}");
        }
    }

    private static bool Same(JsonNode? got, object? want) => want switch
    {
        null => got is null,
        bool b => got is JsonValue v && v.TryGetValue<bool>(out var g) && g == b,
        string s => got is JsonValue v && v.TryGetValue<string>(out var g) && g == s,
        _ => got is JsonValue v && v.TryGetValue<decimal>(out var g) && g == Convert.ToDecimal(want, CultureInfo.InvariantCulture),
    };
}
