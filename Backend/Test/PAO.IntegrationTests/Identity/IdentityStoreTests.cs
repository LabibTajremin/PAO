using Microsoft.EntityFrameworkCore;
using Npgsql;
using PAO.Core.Areas.Identity.Repositories;
using PAO.Core.Areas.Identity.Services;
using PAO.EF;
using PAO.EF.Connection;
using PAO.Infrastructure.Crypto;
using PAO.Infrastructure.Data;
using PAO.Infrastructure.Outbox;
using PAO.Infrastructure.Redis;
using PAO.Lib.Areas.Identity;
using PAO.Lib.Errors;
using PAO.TestKit;
using StackExchange.Redis;

namespace PAO.IntegrationTests.Identity;

public sealed class IdentityStoreTests(MigratedDatabase database) : IClassFixture<MigratedDatabase>, IAsyncLifetime
{
    private const string Phone = "+8801712345678";
    private readonly IConnectionMultiplexer redis = Hosts.Redis();
    private readonly RedisKeys keys = new(TestEnvironment.Unique("t"));
    private NpgsqlDataSource dataSource = null!;

    public ValueTask InitializeAsync()
    {
        dataSource = PaoDbContextSetup.CreateDataSource(PostgresUrl.ToConnectionString(database.Url));
        return ValueTask.CompletedTask;
    }

    public async ValueTask DisposeAsync()
    {
        await dataSource.DisposeAsync();
        await redis.DisposeAsync();
    }

    private PaoDbContext Db()
    {
        var options = new DbContextOptionsBuilder<PaoDbContext>();
        PaoDbContextSetup.Configure(options, dataSource);
        return new PaoDbContext(options.Options);
    }

    private static IdentityRepository Repository(PaoDbContext db) =>
        new(db, new FakeClock(DateTimeOffset.Parse("2026-10-09T10:00:00Z", System.Globalization.CultureInfo.InvariantCulture)),
            new DataCipher(System.Security.Cryptography.RandomNumberGenerator.GetBytes(32)), new OutboxWriter(new UuidV7Generator(), new SystemClock()));

    private static AccountRecord Account(string phone = "", string email = "") =>
        new() { Id = Guid.NewGuid(), Phone = phone, Email = email, Status = AccountStatus.Active, Roles = [], CreatedAt = DateTimeOffset.UtcNow };

    [Fact]
    public async Task The_repository_reports_constraint_failures()
    {
        await using var db = Db();
        var repo = Repository(db);
        var a = Account(phone: "+8801712345679");
        await repo.CreateAccount(a, CancellationToken.None);
        // Commands run in a transaction, which a failing write rolls back.
        async Task Fails(Func<Task> write)
        {
            await using var transaction = await db.Database.BeginTransactionAsync();
            await Assert.ThrowsAsync<PostgresException>(write);
        }
        await Fails(() => repo.SetRoles(a.Id, ["pilot"], CancellationToken.None));
        await Fails(() => repo.ReplaceRole(new RoleDefinitionRecord("verifier", ["made:up"], []), CancellationToken.None));
        await Fails(() => repo.ReplaceRole(new RoleDefinitionRecord("verifier", [], ["Z99"]), CancellationToken.None));
        Assert.NotEmpty((await repo.AllGrants(CancellationToken.None))["verifier"].Permissions);
    }

    [Fact]
    public async Task An_account_without_credentials_is_no_admin_and_totp_secrets_are_stored_encrypted()
    {
        await using var db = Db();
        var repo = Repository(db);
        var a = Account(email: "A@pao.bd");
        await repo.CreateAccount(a, CancellationToken.None);
        var missing = await Assert.ThrowsAsync<DomainException>(() => repo.AdminByEmail(" a@PAO.bd ", CancellationToken.None));
        Assert.Equal(IdentityReasons.AccountNotFound, missing.Reason);
        await repo.CreateAdminCredentials(a.Id, "h", CancellationToken.None);
        var admin = await repo.AdminByEmail("a@pao.bd", CancellationToken.None);
        var secret = Totp.NewSecret("a@pao.bd").Secret;
        Assert.Equal(("a@pao.bd", "", true), (admin.Email, admin.TotpSecret, admin.MustChangePassword));
        await repo.SaveAdmin(admin with { TotpSecret = secret, LockedUntil = DateTimeOffset.UtcNow, LastLoginAt = DateTimeOffset.UtcNow }, CancellationToken.None);
        Assert.Equal(secret, (await repo.AdminById(a.Id, CancellationToken.None)).TotpSecret);
        await using var command = dataSource.CreateCommand($"SELECT totp_secret_enc FROM identity.admin_credentials WHERE account_id = '{a.Id}'");
        var raw = (byte[])(await command.ExecuteScalarAsync())!;
        Assert.DoesNotContain(secret, System.Text.Encoding.UTF8.GetString(raw), StringComparison.Ordinal);
        Assert.Contains(a.Id, (await repo.ListAdmins(CancellationToken.None)).Select(x => x.Id));
        Assert.False(await repo.IsPhoneBlocked("+8801999999999", CancellationToken.None));
    }

    [Fact]
    public async Task Code_stores_keep_codes_per_purpose_and_phone()
    {
        var codes = new RedisCodeStore(redis, keys);
        await codes.Save("login", Phone, new StoredCode("h", 0));
        await codes.IncrementAttempts("login", Phone);
        Assert.Equal(new StoredCode("h", 1), await codes.Get("login", Phone));
        Assert.Equal(IdentityReasons.CodeExpired, (await Assert.ThrowsAsync<DomainException>(() => codes.Get("delete_account", Phone))).Reason);
        await codes.Delete("login", Phone);
        await Assert.ThrowsAsync<DomainException>(() => codes.Get("login", Phone));
    }

    [Fact]
    public async Task Session_stores_drop_index_entries_of_expired_families_and_report_broken_ones()
    {
        var sessions = new RedisSessionStore(redis, keys);
        var accountId = Guid.NewGuid();
        var live = new Family { Id = Guid.NewGuid(), AccountId = accountId, App = "customer", CurrentHash = "h", AccessTokenId = "j", AccessExpiresAt = DateTimeOffset.FromUnixTimeMilliseconds(1_800_000_000_000) };
        await sessions.Save(live, TimeSpan.FromMinutes(1));
        var database = redis.GetDatabase();
        await database.SetAddAsync(keys.Key("sess", accountId.ToString()), Guid.NewGuid().ToString());
        Assert.Equal([live], await sessions.ListForAccount(accountId));
        Assert.Equal(1, await database.SetLengthAsync(keys.Key("sess", accountId.ToString())));
        await sessions.Delete(live);
        Assert.Empty(await sessions.ListForAccount(accountId));
        var broken = Guid.NewGuid();
        await database.SetAddAsync(keys.Key("sess", accountId.ToString()), broken.ToString());
        await database.StringSetAsync(keys.Key("rt", broken.ToString()), "not-a-hash");
        await Assert.ThrowsAsync<RedisServerException>(() => sessions.ListForAccount(accountId));
    }

    [Fact]
    public async Task Challenge_stores_round_trip_and_refuse_garbage()
    {
        var challenges = new RedisChallengeStore(redis, keys);
        var c = new Challenge { Id = Guid.NewGuid(), AdminId = Guid.NewGuid(), Attempts = 2, EnrolSecret = "S" };
        await challenges.Save(c, TimeSpan.FromMinutes(1));
        Assert.Equal(c, await challenges.Get(c.Id));
        Assert.Contains($"\"AdminID\":\"{c.AdminId}\"", (string)(await redis.GetDatabase().StringGetAsync(keys.Key("mfa", c.Id.ToString())))!, StringComparison.Ordinal);
        await challenges.Delete(c.Id);
        Assert.Equal(IdentityReasons.ChallengeExpired, (await Assert.ThrowsAsync<DomainException>(() => challenges.Get(c.Id))).Reason);
        var garbage = Guid.NewGuid();
        await redis.GetDatabase().StringSetAsync(keys.Key("mfa", garbage.ToString()), "{");
        Assert.Equal("decode challenge", (await Assert.ThrowsAsync<InvalidOperationException>(() => challenges.Get(garbage))).Message);
    }

    [Fact]
    public async Task The_throttle_skips_the_ip_window_for_server_side_sends()
    {
        var clock = new FakeClock(DateTimeOffset.UtcNow);
        var throttle = new RedisSendThrottle(new RateLimiter(redis, clock, new UuidV7Generator()), keys);
        Assert.Equal(TimeSpan.Zero, await throttle.RetryAfter(Phone, "9.9.9.9"));
        Assert.Equal(IdentityRules.ResendAfter, await throttle.RetryAfter(Phone, "9.9.9.9"));
        var ipKey = keys.Key("rl", "otp", "ip", "8.8.8.8");
        for (var i = 0; i < 10; i++)
        {
            await redis.GetDatabase().SortedSetAddAsync(ipKey, $"x{i}", clock.Now.ToUnixTimeMilliseconds());
        }
        const string other = "+8801812345678";
        Assert.True(await throttle.RetryAfter(other, "8.8.8.8") > TimeSpan.Zero);
        clock.Advance(IdentityRules.ResendAfter);
        Assert.Equal(TimeSpan.Zero, await throttle.RetryAfter(other, null));
        clock.Advance(IdentityRules.ResendAfter);
        Assert.Equal(TimeSpan.Zero, await throttle.RetryAfter(Phone, string.Empty));
        clock.Advance(IdentityRules.ResendAfter);
        Assert.Equal(TimeSpan.Zero, await throttle.RetryAfter(Phone, null));
        clock.Advance(IdentityRules.ResendAfter);
        // A fourth send to one phone within 15 minutes waits for the per-phone window.
        Assert.True(await throttle.RetryAfter(Phone, null) > IdentityRules.ResendAfter);
    }
}
