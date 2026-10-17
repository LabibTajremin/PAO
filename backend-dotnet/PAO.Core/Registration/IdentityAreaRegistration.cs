namespace PAO.Core.Registration;

/// <summary>The Identity area's handlers, validators, services and shared contract.</summary>
public static class IdentityAreaRegistration
{
    /// <summary>
    /// Adds the Identity area. Handlers, validators and mapping profiles are found by the mediator's
    /// assembly scan; the area's services and its `IIdentitySharedService` implementation are
    /// registered here once its use cases are ported (P17 tasks 2–5).
    /// </summary>
    public static IServiceCollection AddIdentityArea(this IServiceCollection services) => services;
}
