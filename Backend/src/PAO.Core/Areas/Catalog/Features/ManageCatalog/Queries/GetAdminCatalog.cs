using PAO.Core.Areas.Catalog.Services;
using PAO.Lib.Areas.Catalog;
using PAO.Lib.Mapping;
using PAO.Lib.Mediator;

namespace PAO.Core.Areas.Catalog.Features.ManageCatalog.Queries;

/// <summary>The whole catalog, published or not (A03).</summary>
public sealed record GetAdminCatalog : IQuery<CatalogTreeView>;

/// <summary>Answers <see cref="GetAdminCatalog"/> from the database, never the cache.</summary>
public sealed class GetAdminCatalogHandler(CatalogTreeService tree, IMapper mapper) : IRequestHandler<GetAdminCatalog, CatalogTreeView>
{
    /// <inheritdoc />
    public async Task<CatalogTreeView> Handle(GetAdminCatalog request, CancellationToken cancellationToken) =>
        mapper.Map<CatalogSnapshot, CatalogTreeView>(await tree.All(cancellationToken));
}
