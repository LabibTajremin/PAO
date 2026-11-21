using System.Globalization;
using System.Text.Json.Nodes;
using YamlDotNet.Core;
using YamlDotNet.RepresentationModel;

namespace PAO.Infrastructure.Http.OpenApi;

/// <summary>
/// The bundled OpenAPI document (`Spec/openapi.gen.yaml`, bundled from `Backend/Api/openapi.yaml`)
/// as a JSON tree, with local `$ref` resolution.
/// </summary>
public sealed class SpecDocument(JsonObject root)
{
    /// <summary>The file name next to the API host.</summary>
    public const string FileName = "openapi.gen.yaml";

    /// <summary>The whole document.</summary>
    public JsonObject Root { get; } = root;

    /// <summary>Reads a YAML document.</summary>
    public static SpecDocument Load(string path)
    {
        var yaml = new YamlStream();
        using (var reader = new StreamReader(path))
        {
            yaml.Load(reader);
        }
        return new SpecDocument(ToJson(yaml.Documents[0].RootNode) as JsonObject
            ?? throw new InvalidDataException($"{path}: the OpenAPI document must be a mapping"));
    }

    /// <summary>Follows local `$ref`s (`#/components/...`) until it reaches an object without one.</summary>
    public JsonNode? Resolve(JsonNode? node)
    {
        for (var hops = 0; node is JsonObject obj && obj["$ref"]?.GetValue<string>() is { } reference; hops++)
        {
            if (!reference.StartsWith("#/", StringComparison.Ordinal) || hops > 32)
            {
                throw new InvalidDataException($"unsupported $ref {reference}");
            }
            node = Root;
            foreach (var part in reference[2..].Split('/'))
            {
                node = node?[part.Replace("~1", "/", StringComparison.Ordinal).Replace("~0", "~", StringComparison.Ordinal)];
            }
        }
        return node;
    }

    // Plain (unquoted) scalars are typed as YAML 1.2 core schema types; quoted ones stay strings.
    // Numbers are parsed as JSON so they convert to any numeric type later.
    private static JsonNode? ToJson(YamlNode node) => node switch
    {
        YamlMappingNode map => new JsonObject(map.Children.Select(c =>
            KeyValuePair.Create(((YamlScalarNode)c.Key).Value!, ToJson(c.Value)))),
        YamlSequenceNode seq => new JsonArray([.. seq.Children.Select(ToJson)]),
        _ => Scalar((YamlScalarNode)node),
    };

    private static JsonNode? Scalar(YamlScalarNode scalar)
    {
        var text = scalar.Value ?? string.Empty;
        if (scalar.Style != ScalarStyle.Plain)
        {
            return JsonValue.Create(text);
        }
        return text switch
        {
            "null" or "~" or "" => null,
            "true" => JsonValue.Create(true),
            "false" => JsonValue.Create(false),
            _ when long.TryParse(text, NumberStyles.AllowLeadingSign, CultureInfo.InvariantCulture, out var n) =>
                JsonNode.Parse(n.ToString(CultureInfo.InvariantCulture)),
            _ when double.TryParse(text, NumberStyles.Float, CultureInfo.InvariantCulture, out var d) && double.IsFinite(d) =>
                JsonNode.Parse(d.ToString("R", CultureInfo.InvariantCulture)),
            _ => JsonValue.Create(text),
        };
    }
}
