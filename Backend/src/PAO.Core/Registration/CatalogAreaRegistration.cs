using PAO.Core.Areas.Catalog.Services;
using PAO.Core.Areas.Catalog.Services.Icons;
using PAO.Core.Areas.Catalog.Services.Shared;

namespace PAO.Core.Registration;

/// <summary>The Catalog area's handlers, validators, services and shared contract.</summary>
public static class CatalogAreaRegistration
{
    /// <summary>
    /// Adds the Catalog area: the tree cache, change recording, catalog icons and its
    /// `ICatalogSharedService`. Handlers and validators are found by the mediator's assembly scan.
    /// </summary>
    public static IServiceCollection AddCatalogArea(this IServiceCollection services)
    {
        services
            .AddScoped<CatalogTreeService>()
            .AddSingleton<IconAddress>()
            .AddSingleton<PublicAddresses>()
            .AddScoped<IconFiles>()
            .AddScoped<CatalogChanges>()
            .AddScoped<ICatalogSharedService, CatalogSharedService>();
        // Icon links are fetched without redirects or a proxy, only to public addresses (ADR-0039).
        services.AddHttpClient<IconFetcher>(IconFetcher.ClientName)
            .ConfigurePrimaryHttpMessageHandler(provider => IconHandler(provider.GetRequiredService<PublicAddresses>()));
        return services;
    }

    /// <summary>The handler icon downloads use.</summary>
    public static SocketsHttpHandler IconHandler(PublicAddresses addresses) => new()
    {
        AllowAutoRedirect = false,
        UseProxy = false,
        ConnectCallback = (context, cancellationToken) => addresses.Connect(context.DnsEndPoint, cancellationToken),
    };
}
