namespace PAO.Core.Registration;

/// <summary>The Customer area's handlers, validators, services and shared contract.</summary>
public static class CustomerAreaRegistration
{
    /// <summary>
    /// Adds the Customer area. Handlers, validators and mapping profiles are found by the mediator's
    /// assembly scan; the area's services and its `ICustomerSharedService` implementation are
    /// registered here once its use cases are ported (P17 tasks 2–5).
    /// </summary>
    public static IServiceCollection AddCustomerArea(this IServiceCollection services) => services;
}
