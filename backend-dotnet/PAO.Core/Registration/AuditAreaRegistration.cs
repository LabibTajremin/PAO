namespace PAO.Core.Registration;

/// <summary>The Audit area's handlers, validators, services and shared contract.</summary>
public static class AuditAreaRegistration
{
    /// <summary>
    /// Adds the Audit area. Handlers, validators and mapping profiles are found by the mediator's
    /// assembly scan; the area's services and its `IAuditSharedService` implementation are
    /// registered here once its use cases are ported (P17 tasks 2–5).
    /// </summary>
    public static IServiceCollection AddAuditArea(this IServiceCollection services) => services;
}
