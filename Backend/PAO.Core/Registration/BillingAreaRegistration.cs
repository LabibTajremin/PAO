using PAO.Core.Areas.Billing.Services;
using PAO.Core.Areas.Billing.Services.Shared;
using PAO.Infrastructure.Events;

namespace PAO.Core.Registration;

/// <summary>The Billing area's handlers, validators, services and shared contract.</summary>
public static class BillingAreaRegistration
{
    /// <summary>
    /// Adds the Billing area (ADR-0035): its commission subscriber, its due service and its
    /// `IBillingSharedService`, which turns on Booking's due check before an accept. Handlers,
    /// validators and mapping profiles are found by the mediator's assembly scan; the
    /// repository comes from `AddRepositories`.
    /// </summary>
    public static IServiceCollection AddBillingArea(this IServiceCollection services) => services
        .AddSingleton<IEventSubscriptions, BillingSubscriptions>()
        .AddScoped<BillingAccounts>()
        .AddScoped<IBillingSharedService, BillingSharedService>();
}
