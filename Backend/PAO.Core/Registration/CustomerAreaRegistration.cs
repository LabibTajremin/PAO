using PAO.Core.Areas.Customer.Services;
using PAO.Core.Areas.Customer.Services.Shared;
using PAO.Infrastructure.Events;

namespace PAO.Core.Registration;

/// <summary>The Customer area's handlers, validators, services and shared contract.</summary>
public static class CustomerAreaRegistration
{
    /// <summary>
    /// Adds the Customer area: profiles, the peers it reads lazily, its event subscribers and
    /// its `ICustomerSharedService`. Handlers, validators and mapping profiles are found by the
    /// mediator's assembly scan.
    /// </summary>
    public static IServiceCollection AddCustomerArea(this IServiceCollection services) => services
        .AddSingleton<IEventSubscriptions, CustomerSubscriptions>()
        .AddScoped<CustomerPeers>()
        .AddScoped<CustomerProfiles>()
        .AddScoped<ICustomerSharedService, CustomerSharedService>();
}
