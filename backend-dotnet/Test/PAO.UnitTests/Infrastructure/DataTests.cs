using Npgsql;
using PAO.Infrastructure.Data;
using PAO.TestKit;

namespace PAO.UnitTests.Infrastructure;

public sealed class ClockAndIdTests
{
    [Fact]
    public void The_system_clock_is_utc_and_ids_are_time_ordered_uuid_v7()
    {
        var now = new SystemClock().Now;
        Assert.Equal(TimeSpan.Zero, now.Offset);
        Assert.True((DateTimeOffset.UtcNow - now).Duration() < TimeSpan.FromMinutes(1));
        var ids = new UuidV7Generator();
        var first = ids.NewId();
        Assert.Equal(7, first.Version);
        Assert.True(string.CompareOrdinal(first.ToString(), ids.NewId().ToString()) <= 0);
        Assert.Equal(TimeSpan.FromHours(6), DhakaTime.Offset);
    }
}

public sealed class BatchLoaderTests
{
    [Fact]
    public async Task Loads_distinct_keys_with_one_call_and_skips_empty_input()
    {
        var calls = new List<IReadOnlyCollection<int>>();
        Task<IEnumerable<KeyValuePair<int, string>>> Load(IReadOnlyCollection<int> keys, CancellationToken _)
        {
            calls.Add(keys);
            return Task.FromResult(keys.Where(k => k != 3).Select(k => KeyValuePair.Create(k, $"v{k}")));
        }
        var loaded = await BatchLoader.LoadMany([1, 2, 2, 3], Load, CancellationToken.None);
        Assert.Single(calls);
        Assert.Equal([1, 2, 3], calls[0]);
        Assert.Equal("v2", loaded[2]);
        Assert.False(loaded.ContainsKey(3));
        Assert.Empty(await BatchLoader.LoadMany(Array.Empty<int>(), Load, CancellationToken.None));
        Assert.Single(calls);
    }

    [Fact]
    public void Groups_rows_for_one_to_many_loads()
    {
        var grouped = BatchLoader.GroupBy(["a1", "a2", "b1"], s => s[0]);
        Assert.Equal(["a1", "a2"], grouped['a']);
        Assert.Single(grouped['b']);
    }
}

public sealed class ReferenceDataCacheTests
{
    [Fact]
    public async Task Shares_a_load_until_it_expires_or_is_invalidated()
    {
        var clock = new FakeClock(DateTimeOffset.UnixEpoch);
        var cache = new ReferenceDataCache(clock);
        var loads = 0;
        Task<int> Load(CancellationToken _) => Task.FromResult(++loads);
        Assert.Equal(1, await cache.Get("catalog", TimeSpan.FromMinutes(1), Load, CancellationToken.None));
        Assert.Equal(1, await cache.Get("catalog", TimeSpan.FromMinutes(1), Load, CancellationToken.None));
        clock.Advance(TimeSpan.FromMinutes(2));
        Assert.Equal(2, await cache.Get("catalog", TimeSpan.FromMinutes(1), Load, CancellationToken.None));
        cache.Invalidate("catalog");
        Assert.Equal(3, await cache.Get("catalog", TimeSpan.FromMinutes(1), Load, CancellationToken.None));
    }

    [Fact]
    public async Task Forgets_a_failed_load_so_the_next_call_retries()
    {
        var cache = new ReferenceDataCache(new FakeClock(DateTimeOffset.UnixEpoch));
        await Assert.ThrowsAsync<InvalidOperationException>(() =>
            cache.Get<int>("settings", TimeSpan.FromMinutes(1), _ => throw new InvalidOperationException("db down"), CancellationToken.None));
        Assert.Equal(7, await cache.Get("settings", TimeSpan.FromMinutes(1), _ => Task.FromResult(7), CancellationToken.None));
    }
}

public sealed class PostgresErrorsTests
{
    private static PostgresException Violation(string state, string? constraint = null) =>
        new("duplicate", "ERROR", "ERROR", state, constraintName: constraint);

    [Fact]
    public void Detects_unique_violations_through_causes_and_by_constraint()
    {
        var wrapped = new InvalidOperationException("save", Violation(PostgresErrorCodes.UniqueViolation, "accounts_phone_key"));
        Assert.True(PostgresErrors.IsUniqueViolation(wrapped));
        Assert.True(PostgresErrors.IsUniqueViolation(wrapped, "accounts_phone_key"));
        Assert.False(PostgresErrors.IsUniqueViolation(wrapped, "other"));
        Assert.False(PostgresErrors.IsUniqueViolation(Violation(PostgresErrorCodes.ForeignKeyViolation)));
        Assert.False(PostgresErrors.IsUniqueViolation(null));
    }

    [Fact]
    public void Quotes_identifiers()
    {
        Assert.Equal("\"booking\".\"outbox\"", PostgresErrors.QualifiedTable("booking", "outbox"));
        Assert.Equal("\"a\"\"b\"", PostgresErrors.Quote("a\"b"));
    }
}
