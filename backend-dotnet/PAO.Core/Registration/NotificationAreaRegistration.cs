namespace PAO.Core.Registration;

/// <summary>The Notification area's handlers, validators, services and shared contract.</summary>
public static class NotificationAreaRegistration
{
    /// <summary>
    /// Adds the Notification area. Handlers, validators and mapping profiles are found by the mediator's
    /// assembly scan; the area's services and its `INotificationSharedService` implementation are
    /// registered here once its use cases are ported (P17 tasks 2–5).
    /// </summary>
    public static IServiceCollection AddNotificationArea(this IServiceCollection services) => services;
}
