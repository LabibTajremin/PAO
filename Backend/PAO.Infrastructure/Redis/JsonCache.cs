using System.Text.Json;
using StackExchange.Redis;

namespace PAO.Infrastructure.Redis;

/// <summary>Stores rebuildable values (rendered catalog trees, settings, dashboards) as JSON.</summary>
public sealed class JsonCache(IConnectionMultiplexer redis)
{
    private static readonly JsonSerializerOptions Json = new(JsonSerializerDefaults.Web);

    /// <summary>Returns the cached value, or default when absent.</summary>
    public async Task<T?> Get<T>(string key)
    {
        var raw = await redis.GetDatabase().StringGetAsync(key);
        return raw.IsNull ? default : JsonSerializer.Deserialize<T>((string)raw!, Json);
    }

    /// <summary>Stores `value` for `ttl`.</summary>
    public Task Set<T>(string key, T value, TimeSpan ttl) =>
        redis.GetDatabase().StringSetAsync(key, JsonSerializer.Serialize(value, Json), ttl);

    /// <summary>Forgets a value.</summary>
    public Task Delete(string key) => redis.GetDatabase().KeyDeleteAsync(key);
}

/// <summary>
/// Revoked access-token ids (logout, ban, role change), kept until the token would have
/// expired anyway: `deny:jti:{jti}`.
/// </summary>
public sealed class Denylist(IConnectionMultiplexer redis, RedisKeys keys)
{
    /// <summary>Revokes `jti` for `ttl`, the token's remaining lifetime; nothing to do once expired.</summary>
    public async Task Deny(string jti, TimeSpan ttl)
    {
        if (ttl <= TimeSpan.Zero)
        {
            return;
        }
        await redis.GetDatabase().StringSetAsync(keys.Key("deny", "jti", jti), "1", ttl);
    }

    /// <summary>Reports whether `jti` was revoked.</summary>
    public Task<bool> IsDenied(string jti) => redis.GetDatabase().KeyExistsAsync(keys.Key("deny", "jti", jti));
}
