using System.Collections.Concurrent;

namespace PAO.Infrastructure.Data;

/// <summary>
/// Keeps small reference data (catalog, settings, role grants) in process memory for a
/// while, so hot paths do not query it per request. Concurrent callers share one load; a
/// failed load is forgotten so the next call retries; writers call <see cref="Invalidate"/>.
/// </summary>
public sealed class ReferenceDataCache(IClock clock)
{
    private readonly ConcurrentDictionary<string, Entry> entries = new(StringComparer.Ordinal);

    /// <summary>Returns the cached value of `key`, loading it when missing or older than `ttl`.</summary>
    public async Task<T> Get<T>(string key, TimeSpan ttl, Func<CancellationToken, Task<T>> load, CancellationToken cancellationToken)
    {
        var now = clock.Now;
        var entry = entries.AddOrUpdate(
            key,
            _ => NewEntry(load, now + ttl),
            (_, current) => current.ExpiresAt > now ? current : NewEntry(load, now + ttl));
        try
        {
            return (T)await entry.Value.Value.WaitAsync(cancellationToken);
        }
        catch (Exception) when (entry.Value.Value.IsFaulted)
        {
            entries.TryRemove(new KeyValuePair<string, Entry>(key, entry));
            throw;
        }
    }

    /// <summary>Forgets `key`, e.g. after the catalog version changed.</summary>
    public void Invalidate(string key) => entries.TryRemove(key, out _);

    private static Entry NewEntry<T>(Func<CancellationToken, Task<T>> load, DateTimeOffset expiresAt) =>
        new(new Lazy<Task<object>>(async () => (await load(CancellationToken.None))!), expiresAt);

    private sealed record Entry(Lazy<Task<object>> Value, DateTimeOffset ExpiresAt);
}
