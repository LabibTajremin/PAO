using PAO.Core.Areas.Booking.Services;
using PAO.Core.Areas.Booking.Services.Shared;
using PAO.Infrastructure.Events;

namespace PAO.Core.Registration;

/// <summary>The Booking area's handlers, validators, services and shared contract.</summary>
public static class BookingAreaRegistration
{
    /// <summary>
    /// Adds the Booking area: access, pricing, the peers it reads lazily, the erasure
    /// subscriber and its `IBookingSharedService`. Handlers, validators and mapping profiles
    /// are found by the mediator's assembly scan; the expiry job lives in PAO.BackgroundJobs.
    /// </summary>
    public static IServiceCollection AddBookingArea(this IServiceCollection services) => services
        .AddSingleton<IEventSubscriptions, BookingSubscriptions>()
        .AddScoped<BookingPeers>()
        .AddScoped<BookingAccess>()
        .AddScoped<BookingPricing>()
        .AddScoped<IBookingSharedService, BookingSharedService>();
}
