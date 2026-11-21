using System.Globalization;
using PAO.Core.Areas.Identity.Services;
using PAO.Infrastructure.Redis;
using PAO.Lib.Errors;
using StackExchange.Redis;

namespace PAO.Core.Areas.Identity.Repositories;

/// <summary>Codes as hashes `otp:{purpose}:{phone}` = `{h: hash, a: attempts}`, the layout existing sessions use.</summary>
public sealed class RedisCodeStore(IConnectionMultiplexer redis, RedisKeys keys) : ICodeStore
{
    /// <inheritdoc />
    public async Task Save(string purpose, string phone, StoredCode code)
    {
        var key = Key(purpose, phone);
        var transaction = redis.GetDatabase().CreateTransaction();
        _ = transaction.KeyDeleteAsync(key);
        _ = transaction.HashSetAsync(key, [new("h", code.Hash), new("a", code.Attempts)]);
        _ = transaction.KeyExpireAsync(key, IdentityRules.CodeTtl);
        await transaction.ExecuteAsync();
    }

    /// <inheritdoc />
    public async Task<StoredCode> Get(string purpose, string phone)
    {
        var fields = (await redis.GetDatabase().HashGetAllAsync(Key(purpose, phone))).ToDictionary(e => (string)e.Name!, e => (string)e.Value!);
        if (!fields.TryGetValue("h", out var hash) || hash.Length == 0)
        {
            throw new DomainException(IdentityReasons.CodeExpired);
        }
        return new StoredCode(hash, int.Parse(fields.GetValueOrDefault("a", "0"), CultureInfo.InvariantCulture));
    }

    /// <inheritdoc />
    public Task IncrementAttempts(string purpose, string phone) => redis.GetDatabase().HashIncrementAsync(Key(purpose, phone), "a");

    /// <inheritdoc />
    public Task Delete(string purpose, string phone) => redis.GetDatabase().KeyDeleteAsync(Key(purpose, phone));

    private string Key(string purpose, string phone) => keys.Key("otp", purpose, phone);
}

/// <summary>
/// The send windows as sliding-window limits: `rl:otp:resend:{phone}`, `rl:otp:phone:{phone}`
/// and, for app requests, `rl:otp:ip:{ip}`.
/// </summary>
public sealed class RedisSendThrottle(RateLimiter limiter, RedisKeys keys) : ISendThrottle
{
    /// <inheritdoc />
    public async Task<TimeSpan> RetryAfter(string phone, string? clientIp)
    {
        var windows = new List<(string Key, int Limit, TimeSpan Window)>
        {
            (keys.Key("rl", "otp", "resend", phone), 1, IdentityRules.ResendAfter),
            (keys.Key("rl", "otp", "phone", phone), IdentityRules.PerPhone.Limit, IdentityRules.PerPhone.Window),
        };
        if (!string.IsNullOrEmpty(clientIp))
        {
            windows.Add((keys.Key("rl", "otp", "ip", clientIp), IdentityRules.PerIp.Limit, IdentityRules.PerIp.Window));
        }
        // Sequential on purpose: a refused window must not consume the later ones.
        foreach (var (key, limit, window) in windows)
        {
            var decision = await limiter.Allow(key, limit, window);
            if (!decision.Allowed)
            {
                return decision.RetryAfter;
            }
        }
        return TimeSpan.Zero;
    }
}
