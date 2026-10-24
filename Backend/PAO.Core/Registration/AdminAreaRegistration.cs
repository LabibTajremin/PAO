using PAO.Core.Areas.Admin.Services;
using PAO.Core.Areas.Admin.Services.Shared;
using PAO.Infrastructure.Events;

namespace PAO.Core.Registration;

/// <summary>The Admin area's handlers, validators, services and shared contract.</summary>
public static class AdminAreaRegistration
{
    /// <summary>
    /// Adds the Admin area: settings with their cache, the console over the areas it reads
    /// lazily, the dashboard subscribers and its `IAdminSharedService`. Handlers, validators and
    /// mapping profiles are found by the mediator's assembly scan; repositories come from `AddRepositories`.
    /// </summary>
    public static IServiceCollection AddAdminArea(this IServiceCollection services) => services
        .AddSingleton<IEventSubscriptions, AdminStatsSubscriptions>()
        .AddScoped<SettingValues>()
        .AddScoped<AdminPeers>()
        .AddScoped<AdminConsole>()
        .AddScoped<IAdminSharedService, AdminSharedService>();
}
