namespace PAO.Core.Registration;

/// <summary>The Merchant area's handlers, validators, services and shared contract.</summary>
public static class MerchantAreaRegistration
{
    /// <summary>
    /// Adds the Merchant area. Handlers, validators and mapping profiles are found by the mediator's
    /// assembly scan; the area's services and its `IMerchantSharedService` implementation are
    /// registered here once its use cases are ported (P17 tasks 2–5).
    /// </summary>
    public static IServiceCollection AddMerchantArea(this IServiceCollection services) => services;
}
