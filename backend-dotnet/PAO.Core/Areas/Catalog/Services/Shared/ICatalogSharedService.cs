using PAO.Lib.Areas.Catalog;

namespace PAO.Core.Areas.Catalog.Services.Shared;

/// <summary>
/// What other areas may ask of the Catalog area; the only way they reach it (PRD §9.3
/// rule 1, enforced by the architecture tests).
/// </summary>
public interface ICatalogSharedService
{
    /// <summary>Returns a service with its rules (radius, level, women-only), or throws `catalog.service_not_found`.</summary>
    Task<CatalogService> GetService(Guid serviceId, CancellationToken cancellationToken);

    /// <summary>Returns the current price version of a sub-service so a booking can copy it (PRD §4), or throws `catalog.sub_service_not_found`.</summary>
    Task<PriceSnapshot> GetPriceSnapshot(Guid subServiceId, CancellationToken cancellationToken);

    /// <summary>Returns every published service, for enrolment and admin filters.</summary>
    Task<IReadOnlyList<CatalogService>> ListServices(CancellationToken cancellationToken);
}
