using PAO.Core.Areas.Notification.Services;
using PAO.Core.Areas.Notification.Services.Shared;
using PAO.Infrastructure.Events;
using PAO.Lib.Areas.Notification;
using PAO.Lib.Mapping;

namespace PAO.Core.Registration;

/// <summary>The Notification area's handlers, validators, services and shared contract.</summary>
public static class NotificationAreaRegistration
{
    /// <summary>
    /// Adds the Notification area: its mapping profile, the sender, the peers it reads,
    /// the event subscribers and its `INotificationSharedService`. Handlers are found by the
    /// mediator's assembly scan; push and SMS adapters are platform services.
    /// </summary>
    public static IServiceCollection AddNotificationArea(this IServiceCollection services) => services
        .AddSingleton<IMappingProfile, NotificationMappingProfile>()
        .AddSingleton<IEventSubscriptions, NotificationEventSubscriptions>()
        .AddScoped<NotificationSender>()
        .AddScoped<NotificationPeers>()
        .AddScoped<NotificationEventNotes>()
        .AddScoped<INotificationSharedService, NotificationSharedService>();
}
