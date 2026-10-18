using PAO.Core.Areas.Catalog.Repositories;
using PAO.Lib.Areas.Catalog;
using PAO.Lib.Errors;

namespace PAO.Core.Areas.Catalog.Services.Shared;

/// <summary>The Catalog contract for the other areas.</summary>
public sealed class CatalogSharedService(CatalogRepository repository, CatalogTreeService tree) : ICatalogSharedService
{
    /// <inheritdoc />
    public async Task<CatalogService> GetService(Guid serviceId, CancellationToken cancellationToken) =>
        ToContract(await NotFoundAs(CatalogErrors.ServiceNotFound, () => repository.Service(serviceId, cancellationToken)));

    /// <inheritdoc />
    public async Task<PriceSnapshot> GetPriceSnapshot(Guid subServiceId, CancellationToken cancellationToken)
    {
        var sub = await NotFoundAs(CatalogErrors.SubServiceNotFound, () => repository.SubService(subServiceId, cancellationToken));
        var service = await repository.Service(sub.ServiceId, cancellationToken);
        return new PriceSnapshot
        {
            SubServiceId = sub.Id,
            ServiceId = sub.ServiceId,
            PriceVersionId = sub.PriceVersionId,
            Name = sub.Name,
            Unit = sub.Unit,
            AmountPaisa = sub.Price,
            MaxQuantity = sub.MaxQuantity,
            Published = sub.Published && service.Published,
        };
    }

    /// <inheritdoc />
    public async Task<IReadOnlyList<CatalogService>> ListServices(CancellationToken cancellationToken) =>
        [.. CatalogRules.ServicesOf((await tree.Published(cancellationToken)).Categories).Select(ToContract)];

    private static async Task<T> NotFoundAs<T>(string reason, Func<Task<T>> work)
    {
        try
        {
            return await work();
        }
        catch (DomainException error) when (error.Reason == CatalogReasons.NotFound)
        {
            throw new DomainException(reason, error);
        }
    }

    private static CatalogService ToContract(ServiceNode s) => new()
    {
        Id = s.Id,
        CategoryId = s.CategoryId,
        Name = s.Name,
        Model = s.Model,
        RequiredLevel = s.RequiredLevel,
        SearchRadiusM = s.SearchRadiusM,
        WomenProvidersOnly = s.WomenProvidersOnly,
        RequiresLevel2 = s.RequiresLevel2,
        Level2Checklist = s.Level2Checklist,
        Published = s.Published,
    };
}
