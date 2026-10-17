namespace PAO.Core.Areas;

/// <summary>
/// Registers every area's shared services, repositories, event subscriptions and jobs. Each
/// area adds its own `Add{Area}Area` call here as its use cases are ported (P17 tasks 2–5);
/// handlers, validators and mapping profiles are found by the mediator's assembly scan.
/// </summary>
public static class AreaRegistration
{
    /// <summary>The ASP.NET area names, one per module (ADR-0034).</summary>
    public static readonly IReadOnlyList<string> Names =
    [
        "Identity", "Customer", "Merchant", "Verification", "Catalog", "Booking",
        "Rating", "Notification", "Media", "Audit", "Admin", "Billing",
    ];

    /// <summary>Adds the areas to `services`; no area serves a use case yet.</summary>
    public static IServiceCollection AddAreas(this IServiceCollection services) => services;
}
