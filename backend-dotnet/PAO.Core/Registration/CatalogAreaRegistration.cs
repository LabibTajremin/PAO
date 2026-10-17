namespace PAO.Core.Registration;

/// <summary>The Catalog area's handlers, validators, services and shared contract.</summary>
public static class CatalogAreaRegistration
{
    /// <summary>
    /// Adds the Catalog area. Handlers, validators and mapping profiles are found by the mediator's
    /// assembly scan; the area's services and its `ICatalogSharedService` implementation are
    /// registered here once its use cases are ported (P17 tasks 2–5).
    /// </summary>
    public static IServiceCollection AddCatalogArea(this IServiceCollection services) => services;
}
