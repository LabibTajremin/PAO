namespace PAO.Core.Registration;

/// <summary>The Booking area's handlers, validators, services and shared contract.</summary>
public static class BookingAreaRegistration
{
    /// <summary>
    /// Adds the Booking area. Handlers, validators and mapping profiles are found by the mediator's
    /// assembly scan; the area's services and its `IBookingSharedService` implementation are
    /// registered here once its use cases are ported (P17 tasks 2–5).
    /// </summary>
    public static IServiceCollection AddBookingArea(this IServiceCollection services) => services;
}
