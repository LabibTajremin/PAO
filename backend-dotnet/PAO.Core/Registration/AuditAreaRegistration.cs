using PAO.Core.Areas.Audit.Services;
using PAO.Core.Areas.Audit.Services.Shared;
using PAO.Infrastructure.Events;
using PAO.Lib.Areas.Audit;
using PAO.Lib.Mapping;

namespace PAO.Core.Registration;

/// <summary>The Audit area's handlers, validators, services and shared contract.</summary>
public static class AuditAreaRegistration
{
    /// <summary>
    /// Adds the Audit area's log, its event subscriptions (used by the worker) and its
    /// `IAuditSharedService`. Handlers and validators are found by the mediator's assembly
    /// scan; the mapping profile lives in PAO.Lib, outside that scan, so it is added here.
    /// The repository comes from `AddRepositories`.
    /// </summary>
    public static IServiceCollection AddAuditArea(this IServiceCollection services) => services
        .AddSingleton<IMappingProfile, AuditMappingProfile>()
        .AddScoped<AuditLog>()
        .AddSingleton<IEventSubscriptions, AuditSubscriptions>()
        .AddScoped<IAuditSharedService, AuditSharedService>();
}
