namespace PAO.Core.Registration;

/// <summary>The Verification area's handlers, validators, services and shared contract.</summary>
public static class VerificationAreaRegistration
{
    /// <summary>
    /// Adds the Verification area. Handlers, validators and mapping profiles are found by the mediator's
    /// assembly scan; the area's services and its `IVerificationSharedService` implementation are
    /// registered here once its use cases are ported (P17 tasks 2–5).
    /// </summary>
    public static IServiceCollection AddVerificationArea(this IServiceCollection services) => services;
}
