using PAO.Core.Areas.Rating.Services;
using PAO.Core.Areas.Rating.Services.Shared;
using PAO.Infrastructure.Events;

namespace PAO.Core.Registration;

/// <summary>The Rating area's handlers, validators, services and shared contract.</summary>
public static class RatingAreaRegistration
{
    /// <summary>
    /// Adds the Rating area: its event subscribers and its `IRatingSharedService`. Handlers,
    /// validators and mapping profiles are found by the mediator's assembly scan; the
    /// repository comes from `AddRepositories`.
    /// </summary>
    public static IServiceCollection AddRatingArea(this IServiceCollection services) => services
        .AddSingleton<IEventSubscriptions, RatingSubscriptions>()
        .AddScoped<IRatingSharedService, RatingSharedService>();
}
