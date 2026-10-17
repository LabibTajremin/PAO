using PAO.EF;
using PAO.EF.Connection;
using PAO.Infrastructure.Data;
using PAO.Infrastructure.Rbac;
using PAO.Infrastructure.Redis;
using PAO.TestKit;
using StackExchange.Redis;
using Microsoft.EntityFrameworkCore;

namespace PAO.IntegrationTests;

public sealed class RedisTests : IDisposable
{
    private readonly IConnectionMultiplexer redis = Hosts.Redis();
    private readonly RedisKeys keys = new(TestEnvironment.Unique("r"));

    public void Dispose() => redis.Dispose();

    [Fact]
    public void Parses_redis_urls()
    {
        var options = RedisUrl.Parse("rediss://user:p%40ss@cache.example:6380/3");
        Assert.True(options.Ssl);
        Assert.Equal("user", options.User);
        Assert.Equal("p@ss", options.Password);
        Assert.Equal(3, options.DefaultDatabase);
        var bare = RedisUrl.Parse("redis://:secret@localhost");
        Assert.Null(bare.User);
        Assert.Equal("secret", bare.Password);
        Assert.Null(RedisUrl.Parse("redis://localhost/").DefaultDatabase);
        Assert.Throws<FormatException>(() => RedisUrl.Parse("http://localhost"));
        Assert.Equal("pao:dev:otp:+880", new RedisKeys("dev").Key("otp", "+880"));
    }

    [Fact]
    public async Task Connects_and_pings()
    {
        using var connection = await RedisUrl.Connect(TestEnvironment.RedisUrl);
        Assert.True(connection.IsConnected);
    }

    [Fact]
    public async Task The_sliding_window_limits_and_tells_when_to_retry()
    {
        var clock = new FakeClock(DateTimeOffset.UtcNow);
        var limiter = new RateLimiter(redis, clock, new UuidV7Generator());
        var key = keys.Key("rl", "test");
        Assert.True((await limiter.Allow(key, 2, TimeSpan.FromMinutes(1))).Allowed);
        Assert.True((await limiter.Allow(key, 2, TimeSpan.FromMinutes(1))).Allowed);
        clock.Advance(TimeSpan.FromSeconds(10));
        var denied = await limiter.Allow(key, 2, TimeSpan.FromMinutes(1));
        Assert.False(denied.Allowed);
        Assert.Equal(TimeSpan.FromSeconds(50), denied.RetryAfter);
        clock.Advance(TimeSpan.FromMinutes(1));
        Assert.True((await limiter.Allow(key, 2, TimeSpan.FromMinutes(1))).Allowed);
    }

    [Fact]
    public async Task Locks_are_exclusive_and_released_only_by_their_holder()
    {
        var locker = new Locker(redis, new UuidV7Generator());
        var key = keys.Key("lock", "booking", "1");
        var lease = await locker.Acquire(key, TimeSpan.FromSeconds(10));
        await Assert.ThrowsAsync<LockHeldException>(() => locker.Acquire(key, TimeSpan.FromSeconds(10)));
        await lease.DisposeAsync();
        await using var again = await locker.Acquire(key, TimeSpan.FromSeconds(10));
        await lease.DisposeAsync();
        Assert.True(await redis.GetDatabase().KeyExistsAsync(key));
    }

    [Fact]
    public async Task Idempotency_records_use_the_nestjs_format()
    {
        var store = new IdempotencyStore(redis);
        var key = keys.Key("idem", "u", "k");
        Assert.True((await store.Reserve(key, "h1")).Reserved);
        Assert.Equal("""{"h":"h1","d":false}""", (string)(await redis.GetDatabase().StringGetAsync(key))!);
        var pending = await store.Reserve(key, "h1");
        Assert.False(pending.Reserved);
        Assert.False(pending.Record.Done);
        await store.Complete(key, "h1", 201, "{}"u8.ToArray());
        Assert.Equal("""{"h":"h1","d":true,"s":201,"b":"e30="}""", (string)(await redis.GetDatabase().StringGetAsync(key))!);
        var done = (await store.Reserve(key, "h1")).Record;
        Assert.Equal(201, done.Status);
        Assert.Equal("{}"u8.ToArray(), done.Body);
        await store.Complete(key, "h1", 0, []);
        Assert.Null((await store.Reserve(key, "h1")).Record.Body);
        await store.Release(key);
        Assert.True((await store.Reserve(key, "h2")).Reserved);
        await redis.GetDatabase().StringSetAsync(key, "not json");
        await Assert.ThrowsAsync<InvalidOperationException>(() => store.Reserve(key, "h2"));
    }

    private sealed record Cached(string Name, int Count);

    [Fact]
    public async Task The_json_cache_and_the_denylist_expire_values()
    {
        var cache = new JsonCache(redis);
        var key = keys.Key("cache", "x");
        Assert.Null(await cache.Get<Cached>(key));
        await cache.Set(key, new Cached("a", 1), TimeSpan.FromMinutes(1));
        Assert.Equal(new Cached("a", 1), await cache.Get<Cached>(key));
        await cache.Delete(key);
        Assert.Null(await cache.Get<Cached>(key));
        var denylist = new Denylist(redis, keys);
        await denylist.Deny("jti-1", TimeSpan.FromMinutes(1));
        await denylist.Deny("jti-2", TimeSpan.Zero);
        Assert.True(await denylist.IsDenied("jti-1"));
        Assert.False(await denylist.IsDenied("jti-2"));
    }
}

public sealed class RbacTests(MigratedDatabase database) : IClassFixture<MigratedDatabase>, IDisposable
{
    private readonly IConnectionMultiplexer redis = Hosts.Redis();
    private readonly RedisKeys keys = new(TestEnvironment.Unique("r"));

    public void Dispose() => redis.Dispose();

    private IDbContextFactory<PaoDbContext> Contexts()
    {
        var options = new DbContextOptionsBuilder<PaoDbContext>();
        PaoDbContextSetup.Configure(options, PaoDbContextSetup.CreateDataSource(PostgresUrl.ToConnectionString(database.Url)));
        return new TestContextFactory(options.Options);
    }

    private sealed class CountingSource(IRbacSource inner) : IRbacSource
    {
        public int Calls { get; private set; }

        public Task<IReadOnlyDictionary<string, Grants>> LoadGrants(IReadOnlyCollection<string> roles, CancellationToken cancellationToken)
        {
            Calls++;
            return inner.LoadGrants(roles, cancellationToken);
        }
    }

    [Fact]
    public async Task Grants_come_from_the_seed_once_then_from_the_versioned_cache()
    {
        var source = new CountingSource(new EfRbacSource(Contexts()));
        var rbac = new RbacChecker(redis, keys, source);
        Assert.Equal(0, await rbac.Version());
        var grants = await rbac.GrantsOf(["customer", "provider", "nobody"], CancellationToken.None);
        Assert.Contains("booking:create", grants.Permissions);
        Assert.Contains("job:respond", grants.Permissions);
        Assert.Equal(grants.Permissions.Distinct().Count(), grants.Permissions.Count);
        Assert.NotEmpty(grants.Screens);
        Assert.True(await rbac.Has(["customer"], "booking:create", CancellationToken.None));
        Assert.False(await rbac.Has(["nobody"], "booking:create", CancellationToken.None));
        Assert.Equal(1, source.Calls);
        Assert.Equal(1, await rbac.BumpVersion());
        await rbac.Has(["customer"], "booking:create", CancellationToken.None);
        Assert.Equal(2, source.Calls);
        await redis.GetDatabase().StringSetAsync(keys.Key("rbac", "version"), "x");
        await Assert.ThrowsAsync<InvalidOperationException>(() => rbac.Version());
    }
}
