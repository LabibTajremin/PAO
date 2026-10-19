using System.Globalization;
using PAO.Core.Areas.Admin.Repositories;
using PAO.Infrastructure.Redis;
using PAO.Lib.Areas.Admin;

namespace PAO.Core.Areas.Admin.Services;

/// <summary>
/// The platform settings (A-10) by key, kept in Redis under `cache:settings`. A cache outage
/// is logged and reads as a miss; a lost invalidation leaves values stale for at most ten minutes.
/// </summary>
public sealed class SettingValues(SettingsRepository repository, JsonCache cache, RedisKeys keys, ILogger<SettingValues> logger)
{
    private static readonly TimeSpan Ttl = TimeSpan.FromMinutes(10);

    // The seeded values (docs/build/04-decisions.md), so a missing or damaged row cannot stop bookings.
    private static readonly Dictionary<string, string> Defaults = new()
    {
        ["booking.accept_timeout_asap_seconds"] = "180",
        ["booking.accept_timeout_scheduled_seconds"] = "1800",
        ["booking.start_code_max_attempts"] = "5",
        ["booking.start_code_lockout_seconds"] = "600",
        ["search.default_radius_m"] = "5000",
        ["quality.rating_floor"] = "3.5",
        ["quality.rating_min_jobs"] = "10",
        ["quality.max_provider_cancellations_30d"] = "3",
        ["verification.police_clearance_validity_days"] = "365",
        ["verification.level2_cooling_off_days"] = "14",
        ["documents.retention_days"] = "365",
    };

    private string Key => keys.Key("cache", "settings");

    /// <summary>Every value by key, from the cache when possible.</summary>
    public async Task<IReadOnlyDictionary<string, string>> Values(CancellationToken cancellationToken)
    {
        try
        {
            if (await cache.Get<Dictionary<string, string>>(Key) is { } cached)
            {
                return cached;
            }
        }
        catch (Exception error) when (error is not OperationCanceledException)
        {
            logger.LogWarning(error, "settings cache read failed");
        }
        var values = (await repository.List(cancellationToken)).ToDictionary(s => s.Key, s => s.Value);
        try
        {
            await cache.Set(Key, values, Ttl);
        }
        catch (Exception error) when (error is not OperationCanceledException)
        {
            logger.LogWarning(error, "settings cache write failed");
        }
        return values;
    }

    /// <summary>Drops the cached values so readers see a change at once.</summary>
    public async Task Invalidate()
    {
        try
        {
            await cache.Delete(Key);
        }
        catch (Exception error) when (error is not OperationCanceledException)
        {
            logger.LogError(error, "settings cache invalidation failed");
        }
    }

    /// <summary>The typed settings, defaults in place of values that do not parse.</summary>
    public async Task<PlatformSettings> Typed(CancellationToken cancellationToken)
    {
        var v = await Values(cancellationToken);
        const long second = 1000;
        const long day = 86_400_000;
        return new PlatformSettings
        {
            AcceptTimeoutAsapMs = Int(v, "booking.accept_timeout_asap_seconds") * second,
            AcceptTimeoutScheduledMs = Int(v, "booking.accept_timeout_scheduled_seconds") * second,
            DefaultSearchRadiusM = (int)Int(v, "search.default_radius_m"),
            RatingFloor = Float(v, "quality.rating_floor"),
            RatingMinJobs = (int)Int(v, "quality.rating_min_jobs"),
            MaxProviderCancellations30d = (int)Int(v, "quality.max_provider_cancellations_30d"),
            StartCodeMaxAttempts = (int)Int(v, "booking.start_code_max_attempts"),
            StartCodeLockoutMs = Int(v, "booking.start_code_lockout_seconds") * second,
            PoliceClearanceValidityMs = Int(v, "verification.police_clearance_validity_days") * day,
            Level2CoolingOffMs = Int(v, "verification.level2_cooling_off_days") * day,
            DocumentRetentionMs = Int(v, "documents.retention_days") * day,
            ServiceAreaGeoJson = v.GetValueOrDefault("service_area.geojson", string.Empty),
        };
    }

    private static long Int(IReadOnlyDictionary<string, string> v, string key) =>
        long.TryParse(v.GetValueOrDefault(key), NumberStyles.AllowLeadingSign, CultureInfo.InvariantCulture, out var n) && Math.Abs(n) < (1L << 53)
            ? n : long.Parse(Defaults[key], CultureInfo.InvariantCulture);

    private static double Float(IReadOnlyDictionary<string, string> v, string key) =>
        double.TryParse(v.GetValueOrDefault(key), NumberStyles.Float, CultureInfo.InvariantCulture, out var f) && !double.IsNaN(f)
            ? f : double.Parse(Defaults[key], CultureInfo.InvariantCulture);
}
