using System.Text.Json;
using System.Text.Json.Serialization;
using StackExchange.Redis;

namespace PAO.Infrastructure.Redis;

/// <summary>What is stored under an idempotency key: the request fingerprint and, once done, the answer.</summary>
public sealed record IdempotencyRecord(string RequestHash, bool Done, int Status = 0, byte[]? Body = null);

/// <summary>The result of <see cref="IdempotencyStore.Reserve"/>: whether this request claimed the key.</summary>
public sealed record Reservation(bool Reserved, IdempotencyRecord Record);

/// <summary>
/// Remembers responses per idempotency key for 24 hours (PRD §9.6). The stored JSON is
/// field for field what the Go and NestJS backends wrote (`h`, `d`, `s`, `b` in base64),
/// so a retry that crosses the cut-over still gets its first answer.
/// </summary>
public sealed class IdempotencyStore(IConnectionMultiplexer redis)
{
    /// <summary>How long a key is remembered.</summary>
    public static readonly TimeSpan Ttl = TimeSpan.FromHours(24);

    /// <summary>Claims `key` for a new request, or returns what is stored; one atomic SET NX GET.</summary>
    public async Task<Reservation> Reserve(string key, string requestHash)
    {
        var pending = new IdempotencyRecord(requestHash, false);
        var previous = await redis.GetDatabase().StringSetAndGetAsync(key, Encode(pending), Ttl, keepTtl: false, When.NotExists);
        return previous.IsNull ? new Reservation(true, pending) : new Reservation(false, Decode(key, previous!));
    }

    /// <summary>Stores the answer of the reserved request.</summary>
    public Task Complete(string key, string requestHash, int status, byte[] body) =>
        redis.GetDatabase().StringSetAsync(key, Encode(new IdempotencyRecord(requestHash, true, status, body)), Ttl);

    /// <summary>Forgets a reservation whose request failed, so the client may retry.</summary>
    public Task Release(string key) => redis.GetDatabase().KeyDeleteAsync(key);

    private static string Encode(IdempotencyRecord record) => JsonSerializer.Serialize(new Stored
    {
        H = record.RequestHash,
        D = record.Done,
        S = record.Status == 0 ? null : record.Status,
        B = record.Body is { Length: > 0 } body ? Convert.ToBase64String(body) : null,
    });

    private static IdempotencyRecord Decode(string key, string raw)
    {
        try
        {
            var stored = JsonSerializer.Deserialize<Stored>(raw)!;
            return new IdempotencyRecord(stored.H, stored.D, stored.S ?? 0, stored.B is null ? null : Convert.FromBase64String(stored.B));
        }
        catch (JsonException e)
        {
            throw new InvalidOperationException($"decode {key}", e);
        }
    }

    private sealed class Stored
    {
        [JsonPropertyName("h")]
        public string H { get; set; } = string.Empty;

        [JsonPropertyName("d")]
        public bool D { get; set; }

        [JsonPropertyName("s")]
        [JsonIgnore(Condition = JsonIgnoreCondition.WhenWritingNull)]
        public int? S { get; set; }

        [JsonPropertyName("b")]
        [JsonIgnore(Condition = JsonIgnoreCondition.WhenWritingNull)]
        public string? B { get; set; }
    }
}
