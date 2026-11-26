using PAO.Infrastructure.Data;
using StackExchange.Redis;

namespace PAO.Infrastructure.Redis;

/// <summary>Thrown when another holder owns the lock.</summary>
public sealed class LockHeldException(string key) : Exception($"lock held by another holder: {key}");

/// <summary>Hands out short-lived distributed locks (`SET NX PX`), e.g. `lock:booking:{id}`.</summary>
public sealed class Locker(IConnectionMultiplexer redis, IIdGenerator ids)
{
    // Deletes the lock only while it still holds our token, so a holder whose lock expired
    // cannot release someone else's.
    private const string ReleaseIfOwner = """
        if redis.call('GET', KEYS[1]) == ARGV[1] then
          return redis.call('DEL', KEYS[1])
        end
        return 0
        """;

    /// <summary>Takes the lock for `ttl` or throws <see cref="LockHeldException"/>; disposing releases it.</summary>
    public async Task<IAsyncDisposable> Acquire(string key, TimeSpan ttl)
    {
        var token = ids.NewId().ToString();
        var db = redis.GetDatabase();
        if (!await db.StringSetAsync(key, token, ttl, When.NotExists))
        {
            throw new LockHeldException(key);
        }
        return new Lease(db, key, token);
    }

    private sealed class Lease(IDatabase db, string key, string token) : IAsyncDisposable
    {
        public async ValueTask DisposeAsync() =>
            await db.ScriptEvaluateAsync(ReleaseIfOwner, [key], [token]);
    }
}
