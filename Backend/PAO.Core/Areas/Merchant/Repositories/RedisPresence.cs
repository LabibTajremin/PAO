using PAO.Infrastructure.Redis;
using PAO.Lib.Areas.Merchant;
using PAO.Lib.Common;
using PAO.Lib.Errors;
using StackExchange.Redis;

namespace PAO.Core.Areas.Merchant.Repositories;

/// <summary>
/// Tracks online merchants and their live position (PRD §11: positions are never kept
/// while offline).
/// </summary>
public interface IPresence
{
    /// <summary>Puts the merchant into the index of each service at `at`.</summary>
    Task Online(Guid id, IReadOnlyList<Guid> services, GeoPoint at);

    /// <summary>Refreshes the position; `provider.offline` when not online.</summary>
    Task Beat(Guid id, IReadOnlyList<Guid> services, GeoPoint at);

    /// <summary>Drops the merchant and their position from every index.</summary>
    Task Offline(Guid id, IReadOnlyList<Guid> services);

    /// <summary>Which of `ids` are online now, in one round trip.</summary>
    Task<IReadOnlySet<Guid>> OnlineAmong(IReadOnlyCollection<Guid> ids);

    /// <summary>Online merchants of the service within `radiusM` of `at`, nearest first, with whole-metre distances.</summary>
    Task<IReadOnlyDictionary<Guid, double>> Near(Guid service, GeoPoint at, int radiusM);

    /// <summary>Merchants marked online whose heartbeat has lapsed.</summary>
    Task<IReadOnlyList<Guid>> Lost();
}

/// <summary>
/// Presence in Redis, the layout existing data uses: a GEO set per service (`presence:svc:{serviceId}`),
/// a heartbeat key per merchant (`presence:hb:{id}`, 90 s) and the set `presence:online`.
/// </summary>
public sealed class RedisPresence(IConnectionMultiplexer redis, RedisKeys keys) : IPresence
{
    /// <summary>Three missed 30-second heartbeats.</summary>
    public static readonly TimeSpan HeartbeatTtl = TimeSpan.FromSeconds(90);

    private const int NearLimit = 200;

    /// <inheritdoc />
    public async Task Online(Guid id, IReadOnlyList<Guid> services, GeoPoint at)
    {
        var tx = redis.GetDatabase().CreateTransaction();
        var writes = services.Select(s => (Task)tx.GeoAddAsync(GeoKey(s), at.Lng, at.Lat, id.ToString())).ToList();
        writes.Add(tx.StringSetAsync(BeatKey(id), "1", HeartbeatTtl));
        writes.Add(tx.SetAddAsync(OnlineKey(), id.ToString()));
        await tx.ExecuteAsync();
        await Task.WhenAll(writes);
    }

    /// <inheritdoc />
    public async Task Beat(Guid id, IReadOnlyList<Guid> services, GeoPoint at)
    {
        if (!await redis.GetDatabase().SetContainsAsync(OnlineKey(), id.ToString()))
        {
            throw new DomainException(MerchantReasons.Offline);
        }
        await Online(id, services, at);
    }

    /// <inheritdoc />
    public async Task Offline(Guid id, IReadOnlyList<Guid> services)
    {
        var tx = redis.GetDatabase().CreateTransaction();
        var writes = services.Select(s => (Task)tx.SortedSetRemoveAsync(GeoKey(s), id.ToString())).ToList();
        writes.Add(tx.KeyDeleteAsync(BeatKey(id)));
        writes.Add(tx.SetRemoveAsync(OnlineKey(), id.ToString()));
        await tx.ExecuteAsync();
        await Task.WhenAll(writes);
    }

    /// <inheritdoc />
    public async Task<IReadOnlySet<Guid>> OnlineAmong(IReadOnlyCollection<Guid> ids)
    {
        var database = redis.GetDatabase();
        var batch = database.CreateBatch();
        var checks = ids.Distinct().Select(id => (Id: id, Alive: batch.KeyExistsAsync(BeatKey(id)))).ToList();
        batch.Execute();
        await Task.WhenAll(checks.Select(c => c.Alive));
        return checks.Where(c => c.Alive.Result).Select(c => c.Id).ToHashSet();
    }

    /// <summary>Members whose heartbeat lapsed are skipped even before the reaper removes them.</summary>
    public async Task<IReadOnlyDictionary<Guid, double>> Near(Guid service, GeoPoint at, int radiusM)
    {
        var rows = await redis.GetDatabase().GeoSearchAsync(
            GeoKey(service), at.Lng, at.Lat, new GeoSearchCircle(radiusM, GeoUnit.Meters), NearLimit, true, Order.Ascending,
            GeoRadiusOptions.WithDistance);
        var hits = rows.Select(r => (Id: Guid.Parse(r.Member.ToString()), DistanceM: Math.Truncate(r.Distance ?? 0))).ToList();
        var alive = await OnlineAmong([.. hits.Select(h => h.Id)]);
        return hits.Where(h => alive.Contains(h.Id)).ToDictionary(h => h.Id, h => h.DistanceM);
    }

    /// <inheritdoc />
    public async Task<IReadOnlyList<Guid>> Lost()
    {
        var marked = (await redis.GetDatabase().SetMembersAsync(OnlineKey())).Select(m => Guid.Parse(m.ToString())).ToList();
        var alive = await OnlineAmong(marked);
        return [.. marked.Where(id => !alive.Contains(id))];
    }

    private string GeoKey(Guid service) => keys.Key("presence", "svc", service.ToString());

    private string BeatKey(Guid id) => keys.Key("presence", "hb", id.ToString());

    private string OnlineKey() => keys.Key("presence", "online");
}
