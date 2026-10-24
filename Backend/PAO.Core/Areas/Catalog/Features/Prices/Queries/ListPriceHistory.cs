using PAO.Core.Areas.Catalog.Repositories;
using PAO.Lib.Areas.Catalog;
using PAO.Lib.Mapping;
using PAO.Lib.Mediator;

namespace PAO.Core.Areas.Catalog.Features.Prices.Queries;

/// <summary>A sub-service's price versions, newest first.</summary>
public sealed record ListPriceHistory(Guid SubServiceId) : IQuery<PriceHistoryView>;

/// <summary>Answers <see cref="ListPriceHistory"/>; `catalog.not_found` for an unknown sub-service.</summary>
public sealed class ListPriceHistoryHandler(CatalogRepository repository, IMapper mapper) : IRequestHandler<ListPriceHistory, PriceHistoryView>
{
    /// <inheritdoc />
    public async Task<PriceHistoryView> Handle(ListPriceHistory request, CancellationToken cancellationToken)
    {
        await repository.SubService(request.SubServiceId, cancellationToken);
        var history = await repository.PriceHistory(request.SubServiceId, cancellationToken);
        return new PriceHistoryView { Items = mapper.MapAll<PriceVersionInfo, PriceVersionView>(history) };
    }
}
