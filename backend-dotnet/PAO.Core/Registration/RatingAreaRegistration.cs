namespace PAO.Core.Registration;

/// <summary>The Rating area's handlers, validators, services and shared contract.</summary>
public static class RatingAreaRegistration
{
    /// <summary>
    /// Adds the Rating area. Handlers, validators and mapping profiles are found by the mediator's
    /// assembly scan; the area's services and its `IRatingSharedService` implementation are
    /// registered here once its use cases are ported (P17 tasks 2–5).
    /// </summary>
    public static IServiceCollection AddRatingArea(this IServiceCollection services) => services;
}
