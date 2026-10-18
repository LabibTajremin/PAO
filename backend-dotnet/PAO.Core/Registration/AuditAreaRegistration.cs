using PAO.Core.Areas.Audit.Services;
using PAO.Core.Areas.Audit.Services.Shared;
using PAO.Infrastructure.Events;

namespace PAO.Core.Registration;

/// <summary>The Audit area's handlers, validators, services and shared contract.</summary>
public static class AuditAreaRegistration
{
    /// <summary>
    /// Adds the Audit area's log, its event subscriptions (used by the worker) and its
    /// `IAuditSharedService`. Handlers, validators and mapping profiles are found by the
    /// mediator's assembly scan; the repository comes from `AddRepositories`.
    /// </summary>
    public static IServiceCollection AddAuditArea(this IServiceCollection services) => services
        .AddScoped<AuditLog>()
        .AddSingleton<IEventSubscriptions, AuditSubscriptions>()
        .AddScoped<IAuditSharedService, AuditSharedService>();
}
