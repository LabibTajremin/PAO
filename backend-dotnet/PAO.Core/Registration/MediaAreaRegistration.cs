namespace PAO.Core.Registration;

/// <summary>The Media area's handlers, validators, services and shared contract.</summary>
public static class MediaAreaRegistration
{
    /// <summary>
    /// Adds the Media area. Handlers, validators and mapping profiles are found by the mediator's
    /// assembly scan; the area's services and its `IMediaSharedService` implementation are
    /// registered here once its use cases are ported (P17 tasks 2–5).
    /// </summary>
    public static IServiceCollection AddMediaArea(this IServiceCollection services) => services;
}
