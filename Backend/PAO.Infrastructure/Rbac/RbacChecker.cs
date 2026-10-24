using System.Globalization;
using PAO.Infrastructure.Redis;
using StackExchange.Redis;

namespace PAO.Infrastructure.Rbac;

/// <summary>
/// Answers "may these roles do this?" and "which screens may they see?" from Redis sets
/// keyed by the RBAC version (`rbac:role:{role}:v{n}`, `rbac:screens:{role}:v{n}`),
/// falling back to the identity tables (02-architecture §6). Keys, marker and TTL match
/// the NestJS backend, so both can share one Redis during the cut-over.
/// </summary>
public sealed class RbacChecker(IConnectionMultiplexer redis, RedisKeys keys, IRbacSource source)
{
    // Distinguishes "cached as empty" from "not cached".
    private const string EmptyMarker = "~";
    private static readonly TimeSpan CacheTtl = TimeSpan.FromHours(1);

    /// <summary>The current RBAC version; 0 before the first change.</summary>
    public async Task<long> Version()
    {
        var raw = await redis.GetDatabase().StringGetAsync(keys.Key("rbac", "version"));
        if (raw.IsNull)
        {
            return 0;
        }
        return long.TryParse((string)raw!, NumberStyles.AllowLeadingSign, CultureInfo.InvariantCulture, out var version)
            ? version
            : throw new InvalidOperationException($"read rbac version: not a number: {raw}");
    }

    /// <summary>Invalidates every cached role after a role or permission change.</summary>
    public Task<long> BumpVersion() => redis.GetDatabase().StringIncrementAsync(keys.Key("rbac", "version"));

    /// <summary>Returns the union of the roles' grants, sorted.</summary>
    public async Task<Grants> GrantsOf(IReadOnlyCollection<string> roles, CancellationToken cancellationToken)
    {
        var version = await Version();
        var cached = await ReadCache(roles, version);
        var missing = roles.Where(r => !cached.ContainsKey(r)).ToArray();
        if (missing.Length > 0)
        {
            var loaded = await source.LoadGrants(missing, cancellationToken);
            WriteCache(loaded, version);
            foreach (var (role, grants) in loaded)
            {
                cached[role] = grants;
            }
        }
        return new Grants(
            [.. cached.Values.SelectMany(g => g.Permissions).Distinct().Order(StringComparer.Ordinal)],
            [.. cached.Values.SelectMany(g => g.Screens).Distinct().Order(StringComparer.Ordinal)]);
    }

    /// <summary>Reports whether any of the roles grants `permission`.</summary>
    public async Task<bool> Has(IReadOnlyCollection<string> roles, string permission, CancellationToken cancellationToken) =>
        (await GrantsOf(roles, cancellationToken)).Permissions.Contains(permission);

    private string PermissionKey(string role, long version) => keys.Key("rbac", "role", role, $"v{version}");

    private string ScreenKey(string role, long version) => keys.Key("rbac", "screens", role, $"v{version}");

    // One pipelined batch for every role instead of a round trip per role.
    private async Task<Dictionary<string, Grants>> ReadCache(IReadOnlyCollection<string> roles, long version)
    {
        var batch = redis.GetDatabase().CreateBatch();
        var reads = roles.Distinct().Select(role => (
            Role: role,
            Permissions: batch.SetMembersAsync(PermissionKey(role, version)),
            Screens: batch.SetMembersAsync(ScreenKey(role, version)))).ToList();
        batch.Execute();
        await Task.WhenAll(reads.SelectMany(r => new[] { r.Permissions, r.Screens }));
        return reads
            .Where(r => r.Permissions.Result.Length > 0)
            .ToDictionary(r => r.Role, r => new Grants(WithoutMarker(r.Permissions.Result), WithoutMarker(r.Screens.Result)));
    }

    // Best effort and fire-and-forget: a lost write only costs another database read.
    private void WriteCache(IReadOnlyDictionary<string, Grants> loaded, long version)
    {
        var batch = redis.GetDatabase().CreateBatch();
        foreach (var (role, grants) in loaded)
        {
            CacheSet(batch, PermissionKey(role, version), grants.Permissions);
            CacheSet(batch, ScreenKey(role, version), grants.Screens);
        }
        batch.Execute();
    }

    private static void CacheSet(IBatch batch, string key, IReadOnlyList<string> members)
    {
        var values = members.Prepend(EmptyMarker).Select(m => (RedisValue)m).ToArray();
        _ = batch.SetAddAsync(key, values, CommandFlags.FireAndForget);
        _ = batch.KeyExpireAsync(key, CacheTtl, flags: CommandFlags.FireAndForget);
    }

    private static string[] WithoutMarker(RedisValue[] members) =>
        [.. members.Select(m => (string)m!).Where(m => m != EmptyMarker).Order(StringComparer.Ordinal)];
}
