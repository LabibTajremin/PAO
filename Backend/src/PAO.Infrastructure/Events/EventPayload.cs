using System.Text.Json;
using PAO.Infrastructure.Crypto;

namespace PAO.Infrastructure.Events;

/// <summary>
/// Reads another area's event the way earlier releases decoded it: a missing field is
/// its zero value (the nil UUID for ids), while a field of the wrong type or a payload that
/// is not an object fails, so the relay retries the event.
/// </summary>
public sealed class EventPayload
{
    private readonly Envelope envelope;

    /// <summary>Wraps the payload of `envelope`; throws when it is not a JSON object.</summary>
    public EventPayload(Envelope envelope)
    {
        if (envelope.Payload.ValueKind != JsonValueKind.Object)
        {
            throw new FormatException($"decode {envelope.Name}: payload is not an object");
        }
        this.envelope = envelope;
    }

    /// <summary>A UUID field; the nil UUID when missing.</summary>
    public string Id(string name) => Read(name, JsonValueKind.String, UuidText.Nil, v => v.GetString()!);

    /// <summary>A string field; empty when missing.</summary>
    public string Text(string name) => Read(name, JsonValueKind.String, string.Empty, v => v.GetString()!);

    /// <summary>A number field; 0 when missing.</summary>
    public double Number(string name) => Read(name, JsonValueKind.Number, 0d, v => v.GetDouble());

    /// <summary>A boolean field; false when missing.</summary>
    public bool Flag(string name) => Kind(name) switch
    {
        JsonValueKind.True => true,
        JsonValueKind.False or JsonValueKind.Undefined or JsonValueKind.Null => false,
        _ => throw new FormatException($"decode {envelope.Name}: {name} is not a boolean"),
    };

    /// <summary>The string items of an array field; empty when missing.</summary>
    public IReadOnlyList<string> Texts(string name) =>
        Read<IReadOnlyList<string>>(name, JsonValueKind.Array, [], v => [.. v.EnumerateArray().Where(i => i.ValueKind == JsonValueKind.String).Select(i => i.GetString()!)]);

    private JsonValueKind Kind(string name) =>
        envelope.Payload.TryGetProperty(name, out var value) ? value.ValueKind : JsonValueKind.Undefined;

    private T Read<T>(string name, JsonValueKind kind, T zero, Func<JsonElement, T> read)
    {
        if (!envelope.Payload.TryGetProperty(name, out var value) || value.ValueKind == JsonValueKind.Null)
        {
            return zero;
        }
        return value.ValueKind == kind
            ? read(value)
            : throw new FormatException($"decode {envelope.Name}: {name} is not a {kind.ToString().ToLowerInvariant()}");
    }
}
