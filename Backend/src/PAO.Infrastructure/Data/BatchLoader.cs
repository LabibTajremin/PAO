namespace PAO.Infrastructure.Data;

/// <summary>
/// Loads related rows for many keys with one query instead of one per row (no N+1, no
/// database calls in loops, ADR-0034). Repositories pass a loader that runs
/// `WHERE id = ANY(@ids)` or `Where(x => ids.Contains(x.Id))`.
/// </summary>
public static class BatchLoader
{
    /// <summary>
    /// Calls `load` once with the distinct keys (never for none) and returns the values by
    /// key; keys the loader did not return are absent.
    /// </summary>
    public static async Task<IReadOnlyDictionary<TKey, TValue>> LoadMany<TKey, TValue>(
        IEnumerable<TKey> keys,
        Func<IReadOnlyCollection<TKey>, CancellationToken, Task<IEnumerable<KeyValuePair<TKey, TValue>>>> load,
        CancellationToken cancellationToken)
        where TKey : notnull
    {
        var distinct = keys.Distinct().ToArray();
        if (distinct.Length == 0)
        {
            return new Dictionary<TKey, TValue>();
        }
        var loaded = await load(distinct, cancellationToken);
        return loaded.ToDictionary(pair => pair.Key, pair => pair.Value);
    }

    /// <summary>Groups `rows` by key, for one-to-many batch loads.</summary>
    public static IReadOnlyDictionary<TKey, IReadOnlyList<TRow>> GroupBy<TKey, TRow>(IEnumerable<TRow> rows, Func<TRow, TKey> keyOf)
        where TKey : notnull =>
        rows.GroupBy(keyOf).ToDictionary(g => g.Key, g => (IReadOnlyList<TRow>)[.. g]);
}
