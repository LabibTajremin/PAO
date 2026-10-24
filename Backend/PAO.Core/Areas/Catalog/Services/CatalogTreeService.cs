using PAO.Core.Areas.Catalog.Repositories;
using PAO.Infrastructure.Redis;
using PAO.Lib.Areas.Catalog;

namespace PAO.Core.Areas.Catalog.Services;

/// <summary>Reads the whole tree: published for the apps (cached in Redis), everything for admins.</summary>
public sealed class CatalogTreeService(CatalogRepository repository, JsonCache cache, RedisKeys keys, ILogger<CatalogTreeService> logger)
{
    // The version in the key already makes edits visible at once; the TTL only bounds how
    // long an unused tree stays in Redis.
    private static readonly TimeSpan CacheTtl = TimeSpan.FromMinutes(10);

    /// <summary>What customers and providers browse, from `cache:catalog:v{version}` while the version is unchanged; a cache failure only costs a database read.</summary>
    public async Task<CatalogSnapshot> Published(CancellationToken cancellationToken)
    {
        var version = await repository.Version(cancellationToken);
        var key = keys.Key("cache", "catalog", $"v{version}");
        var cached = await Cached(key);
        if (cached is not null)
        {
            return new CatalogSnapshot { Version = version, Categories = cached };
        }
        var categories = CatalogRules.PublishedOnly(await repository.Tree(cancellationToken));
        try
        {
            await cache.Set(key, categories, CacheTtl);
        }
        catch (Exception error) when (error is not OperationCanceledException)
        {
            logger.LogWarning(error, "catalog cache write failed");
        }
        return new CatalogSnapshot { Version = version, Categories = categories };
    }

    /// <summary>Everything, published or not (A03).</summary>
    public async Task<CatalogSnapshot> All(CancellationToken cancellationToken)
    {
        var version = await repository.Version(cancellationToken);
        return new CatalogSnapshot { Version = version, Categories = await repository.Tree(cancellationToken) };
    }

    private async Task<List<CategoryNode>?> Cached(string key)
    {
        try
        {
            return await cache.Get<List<CategoryNode>>(key);
        }
        catch (Exception error) when (error is not OperationCanceledException)
        {
            logger.LogWarning(error, "catalog cache read failed");
            return null;
        }
    }
}
