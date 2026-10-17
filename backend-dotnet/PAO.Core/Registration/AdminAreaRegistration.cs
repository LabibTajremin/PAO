namespace PAO.Core.Registration;

/// <summary>The Admin area's handlers, validators, services and shared contract.</summary>
public static class AdminAreaRegistration
{
    /// <summary>
    /// Adds the Admin area. Handlers, validators and mapping profiles are found by the mediator's
    /// assembly scan; the area's services and its `IAdminSharedService` implementation are
    /// registered here once its use cases are ported (P17 tasks 2–5).
    /// </summary>
    public static IServiceCollection AddAdminArea(this IServiceCollection services) => services;
}
