using PAO.Core.Areas.Merchant.Services;
using PAO.Core.Areas.Merchant.Services.Shared;
using PAO.Infrastructure.Events;

namespace PAO.Core.Registration;

/// <summary>The Merchant area's handlers, validators, services and shared contract.</summary>
public static class MerchantAreaRegistration
{
    /// <summary>
    /// Adds the Merchant area: enrolment, presence, search, the read model and its event
    /// subscribers, the peers it reads lazily and its `IMerchantSharedService`. Handlers,
    /// validators and mapping profiles are found by the mediator's assembly scan; the presence
    /// reaper job lives in PAO.BackgroundJobs.
    /// </summary>
    public static IServiceCollection AddMerchantArea(this IServiceCollection services) => services
        .AddSingleton<MerchantReadModel>()
        .AddSingleton<IEventSubscriptions, MerchantSubscriptions>()
        .AddScoped<MerchantPeers>()
        .AddScoped<MerchantProfiles>()
        .AddScoped<MerchantEnrolment>()
        .AddScoped<MerchantPresence>()
        .AddScoped<MerchantFinder>()
        .AddScoped<MerchantViewsBuilder>()
        .AddScoped<IMerchantSharedService, MerchantSharedService>();
}
