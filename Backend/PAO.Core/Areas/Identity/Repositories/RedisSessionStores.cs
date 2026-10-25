using System.Globalization;
using System.Text.Json;
using PAO.Core.Areas.Identity.Services;
using PAO.Infrastructure.Redis;
using PAO.Lib.Errors;
using StackExchange.Redis;

namespace PAO.Core.Areas.Identity.Repositories;

/// <summary>Families as hashes `rt:{familyId}`, indexed by the set `sess:{accountId}`, the layout existing sessions use.</summary>
public sealed class RedisSessionStore(IConnectionMultiplexer redis, RedisKeys keys) : ISessionStore
{
    /// <inheritdoc />
    public async Task Save(Family family, TimeSpan ttl)
    {
        var familyKey = FamilyKey(family.Id);
        var accountKey = AccountKey(family.AccountId);
        var transaction = redis.GetDatabase().CreateTransaction();
        _ = transaction.HashSetAsync(familyKey,
        [
            new("account", family.AccountId.ToString()),
            new("app", family.App),
            new("hash", family.CurrentHash),
            new("jti", family.AccessTokenId),
            new("exp", family.AccessExpiresAt.ToUnixTimeMilliseconds()),
        ]);
        _ = transaction.KeyExpireAsync(familyKey, ttl);
        _ = transaction.SetAddAsync(accountKey, family.Id.ToString());
        _ = transaction.KeyExpireAsync(accountKey, ttl);
        await transaction.ExecuteAsync();
    }

    /// <inheritdoc />
    public async Task<Family> Get(Guid familyId) =>
        ToFamily(familyId, await redis.GetDatabase().HashGetAllAsync(FamilyKey(familyId))) ?? throw new DomainException(IdentityReasons.RefreshInvalid);

    /// <inheritdoc />
    public async Task Delete(Family family)
    {
        var transaction = redis.GetDatabase().CreateTransaction();
        _ = transaction.KeyDeleteAsync(FamilyKey(family.Id));
        _ = transaction.SetRemoveAsync(AccountKey(family.AccountId), family.Id.ToString());
        await transaction.ExecuteAsync();
    }

    /// <summary>The account's live families in one round trip; index entries whose family expired are dropped.</summary>
    public async Task<IReadOnlyList<Family>> ListForAccount(Guid accountId)
    {
        var database = redis.GetDatabase();
        var ids = (await database.SetMembersAsync(AccountKey(accountId))).Select(m => Guid.Parse((string)m!)).ToArray();
        var batch = database.CreateBatch();
        var reads = ids.Select(id => (Id: id, Read: batch.HashGetAllAsync(FamilyKey(id)))).ToArray();
        batch.Execute();
        await Task.WhenAll(reads.Select(r => r.Read));
        var families = reads.Select(r => (r.Id, Family: ToFamily(r.Id, r.Read.Result))).ToArray();
        var expired = families.Where(f => f.Family is null).Select(f => (RedisValue)f.Id.ToString()).ToArray();
        if (expired.Length > 0)
        {
            await database.SetRemoveAsync(AccountKey(accountId), expired);
        }
        return [.. families.Where(f => f.Family is not null).Select(f => f.Family!)];
    }

    private static Family? ToFamily(Guid id, HashEntry[] entries)
    {
        var m = entries.ToDictionary(e => (string)e.Name!, e => (string)e.Value!);
        if (!m.TryGetValue("account", out var account) || account.Length == 0)
        {
            return null;
        }
        return new Family
        {
            Id = id,
            AccountId = Guid.Parse(account),
            App = m.GetValueOrDefault("app", string.Empty),
            CurrentHash = m.GetValueOrDefault("hash", string.Empty),
            AccessTokenId = m.GetValueOrDefault("jti", string.Empty),
            AccessExpiresAt = DateTimeOffset.FromUnixTimeMilliseconds(long.Parse(m.GetValueOrDefault("exp", "0"), CultureInfo.InvariantCulture)),
        };
    }

    private string FamilyKey(Guid id) => keys.Key("rt", id.ToString());

    private string AccountKey(Guid id) => keys.Key("sess", id.ToString());
}

/// <summary>Challenges as the JSON stored under `mfa:{id}`.</summary>
public sealed class RedisChallengeStore(IConnectionMultiplexer redis, RedisKeys keys) : IChallengeStore
{
    private sealed record Stored(string ID, string AdminID, int Attempts, string EnrolSecret);

    /// <inheritdoc />
    public Task Save(Challenge challenge, TimeSpan ttl)
    {
        var stored = new Stored(challenge.Id.ToString(), challenge.AdminId.ToString(), challenge.Attempts, challenge.EnrolSecret);
        return redis.GetDatabase().StringSetAsync(Key(challenge.Id), JsonSerializer.Serialize(stored), ttl);
    }

    /// <inheritdoc />
    public async Task<Challenge> Get(Guid id)
    {
        var raw = await redis.GetDatabase().StringGetAsync(Key(id));
        if (raw.IsNull)
        {
            throw new DomainException(IdentityReasons.ChallengeExpired);
        }
        Stored s;
        try
        {
            s = JsonSerializer.Deserialize<Stored>((string)raw!)!;
        }
        catch (JsonException error)
        {
            throw new InvalidOperationException("decode challenge", error);
        }
        return new Challenge { Id = Guid.Parse(s.ID), AdminId = Guid.Parse(s.AdminID), Attempts = s.Attempts, EnrolSecret = s.EnrolSecret };
    }

    /// <inheritdoc />
    public Task Delete(Guid id) => redis.GetDatabase().KeyDeleteAsync(Key(id));

    private string Key(Guid id) => keys.Key("mfa", id.ToString());
}
