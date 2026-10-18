using PAO.Core.Areas.Media.Services;
using PAO.Core.Areas.Media.Services.Shared;
using PAO.Infrastructure.Events;
using PAO.Lib.Areas.Media;
using PAO.Lib.Mapping;

namespace PAO.Core.Registration;

/// <summary>The Media area's handlers, validators, services and shared contract.</summary>
public static class MediaAreaRegistration
{
    /// <summary>
    /// Adds the Media area: its mapping profile, the file service, the erasure subscriber and
    /// its `IMediaSharedService`. Handlers and validators are found by the mediator's assembly
    /// scan; the orphan purge job lives in PAO.BackgroundJobs.
    /// </summary>
    public static IServiceCollection AddMediaArea(this IServiceCollection services) => services
        .AddSingleton<IMappingProfile, MediaMappingProfile>()
        .AddSingleton<IEventSubscriptions, MediaEventSubscriptions>()
        .AddScoped<MediaFiles>()
        .AddScoped<IMediaSharedService, MediaSharedService>();
}
