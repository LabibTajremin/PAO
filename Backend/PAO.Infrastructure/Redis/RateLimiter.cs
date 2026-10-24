using PAO.Infrastructure.Data;
using StackExchange.Redis;

namespace PAO.Infrastructure.Redis;

/// <summary>The outcome of a rate-limit check.</summary>
public sealed record RateDecision(bool Allowed, TimeSpan RetryAfter);

/// <summary>A sliding-window limiter: at most `limit` hits per window per key (ZSET).</summary>
public sealed class RateLimiter(IConnectionMultiplexer redis, IClock clock, IIdGenerator ids)
{
    // Drops hits older than the window, then records this hit if the limit allows it, in
    // one atomic step. Returns {allowed, oldest hit in ms}. Same script as NestJS.
    private const string SlidingWindow = """
        local key, now, window, limit, member = KEYS[1], tonumber(ARGV[1]), tonumber(ARGV[2]), tonumber(ARGV[3]), ARGV[4]
        redis.call('ZREMRANGEBYSCORE', key, '-inf', now - window)
        if redis.call('ZCARD', key) < limit then
          redis.call('ZADD', key, now, member)
          redis.call('PEXPIRE', key, window)
          return {1, 0}
        end
        local oldest = redis.call('ZRANGE', key, 0, 0, 'WITHSCORES')
        return {0, tonumber(oldest[2])}
        """;

    /// <summary>Records a hit on `key` if fewer than `limit` hits happened within `window`.</summary>
    public async Task<RateDecision> Allow(string key, int limit, TimeSpan window)
    {
        var now = clock.Now.ToUnixTimeMilliseconds();
        var windowMs = (long)window.TotalMilliseconds;
        var result = (RedisResult[])(await redis.GetDatabase().ScriptEvaluateAsync(
            SlidingWindow,
            [key],
            [now, windowMs, limit, $"{now}-{ids.NewId()}"]))!;
        if ((long)result[0] == 1)
        {
            return new RateDecision(true, TimeSpan.Zero);
        }
        var retryMs = Math.Max((long)result[1] + windowMs - now, 1000);
        return new RateDecision(false, TimeSpan.FromMilliseconds(retryMs));
    }
}
