namespace PAO.Core.Registration;

/// <summary>The Billing area's handlers, validators, services and shared contract.</summary>
public static class BillingAreaRegistration
{
    /// <summary>
    /// Adds the Billing area. Handlers, validators and mapping profiles are found by the mediator's
    /// assembly scan; the area's services and its `IBillingSharedService` implementation are
    /// registered here once its use cases are ported (P17 tasks 2–5).
    /// </summary>
    public static IServiceCollection AddBillingArea(this IServiceCollection services) => services;
}
