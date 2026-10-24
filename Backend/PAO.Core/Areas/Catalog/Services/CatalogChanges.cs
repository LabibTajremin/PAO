using PAO.Core.Areas.Catalog.Repositories;
using PAO.Lib.Areas.Catalog;
using PAO.Lib.Errors;

namespace PAO.Core.Areas.Catalog.Services;

/// <summary>
/// Runs a catalog write inside the command's transaction, bumps the catalog version
/// (expiring cached trees) and announces it with `CatalogChanged`.
/// </summary>
public sealed class CatalogChanges(CatalogWriteRepository writer)
{
    /// <summary>Applies `write`, then bumps the version and publishes the change.</summary>
    public async Task Record(Func<CatalogWriteRepository, Task> write, CancellationToken cancellationToken)
    {
        await write(writer);
        var version = await writer.BumpVersion(cancellationToken);
        await writer.Publish("catalog", new CatalogChanged { Version = version }, cancellationToken);
    }

    /// <summary>Throws a domain error with `reason` unless `ok`.</summary>
    public static void Check(bool ok, string reason)
    {
        if (!ok)
        {
            throw new DomainException(reason);
        }
    }
}
