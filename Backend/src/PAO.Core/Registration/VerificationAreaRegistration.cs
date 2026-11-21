using PAO.Core.Areas.Verification.Services;
using PAO.Core.Areas.Verification.Services.Shared;
using PAO.Infrastructure.Events;
using PAO.Infrastructure.Testing;

namespace PAO.Core.Registration;

/// <summary>The Verification area's handlers, validators, services and shared contract.</summary>
public static class VerificationAreaRegistration
{
    /// <summary>
    /// Adds the Verification area: its services, event subscriptions, the document-expiry test
    /// hook and its `IVerificationSharedService`. Handlers and validators are found by the
    /// mediator's assembly scan; the expiry, reminder and purge jobs live in PAO.BackgroundJobs.
    /// </summary>
    public static IServiceCollection AddVerificationArea(this IServiceCollection services) => services
        .AddSingleton<IEventSubscriptions, VerificationEventSubscriptions>()
        .AddScoped<IDocumentExpiry, DocumentExpiryHook>()
        .AddScoped<VerificationPeers>()
        .AddScoped<VerificationStates>()
        .AddScoped<DocumentSteps>()
        .AddScoped<MerchantStatus>()
        .AddScoped<ReviewItems>()
        .AddScoped<Level2Sessions>()
        .AddScoped<DocumentLifecycle>()
        .AddScoped<IVerificationSharedService, VerificationSharedService>();
}
