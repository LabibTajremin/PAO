using PAO.Core.Areas.Catalog.Services;
using PAO.Core.Areas.Catalog.Services.Shared;

namespace PAO.Core.Registration;

/// <summary>The Catalog area's handlers, validators, services and shared contract.</summary>
public static class CatalogAreaRegistration
{
    /// <summary>
    /// Adds the Catalog area: the tree cache, change recording and its
    /// `ICatalogSharedService`. Handlers and validators are found by the mediator's assembly scan.
    /// </summary>
    public static IServiceCollection AddCatalogArea(this IServiceCollection services) => services
        .AddScoped<CatalogTreeService>()
        .AddScoped<CatalogChanges>()
        .AddScoped<ICatalogSharedService, CatalogSharedService>();
}
