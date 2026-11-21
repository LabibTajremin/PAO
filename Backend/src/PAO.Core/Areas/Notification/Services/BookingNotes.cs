using System.Globalization;
using PAO.Infrastructure.Events;
using PAO.Lib.Areas.Booking;
using PAO.Lib.Areas.Notification;

namespace PAO.Core.Areas.Notification.Services;

/// <summary>Who hears about each booking event (02-architecture §8).</summary>
public static class BookingNotes
{
    /// <summary>The recipients of each booking event, by event name.</summary>
    public static readonly IReadOnlyDictionary<string, Func<EventPayload, IReadOnlyList<Note>>> Recipients =
        new Dictionary<string, Func<EventPayload, IReadOnlyList<Note>>>(StringComparer.Ordinal)
        {
            [BookingEvents.BookingRequested] = p => [Provider(p, "booking_requested")],
            [BookingEvents.BookingAccepted] = p => [Customer(p, "booking_accepted")],
            [BookingEvents.BookingRejected] = p => [Customer(p, "booking_rejected")],
            [BookingEvents.BookingTimedOut] = p => [Customer(p, "booking_timed_out"), Provider(p, "request_missed")],
            [BookingEvents.ProviderOnTheWay] = p => [Customer(p, "provider_on_the_way")],
            [BookingEvents.ProviderArrived] = p => [Customer(p, "provider_arrived")],
            [BookingEvents.BookingStarted] = p => [Customer(p, "booking_started")],
            [BookingEvents.ExtraItemsProposed] = p =>
                [Customer(p, "extras_proposed") with { Extra = new Dictionary<string, string> { ["added"] = Taka(p.Number("addedPaisa")) } }],
            [BookingEvents.ExtraItemsDecided] = p =>
                [Provider(p, "extras_decided") with { Extra = new Dictionary<string, string> { ["decision"] = p.Flag("approved") ? "approved" : "declined" } }],
            [BookingEvents.BookingCompleted] = p => [Customer(p, "booking_completed"), Provider(p, "booking_completed")],
            [BookingEvents.BookingCancelled] = p =>
                p.Text("by") == "customer" ? [Provider(p, "booking_cancelled")] : [Customer(p, "booking_cancelled")],
        };

    private static Note Customer(EventPayload p, string template) => new(p.Id("customerId"), NotificationApp.Customer, template);

    private static Note Provider(EventPayload p, string template) => new(p.Id("providerId"), NotificationApp.Partner, template);

    private static string Taka(double paisa) => Math.Truncate(paisa / 100).ToString(CultureInfo.InvariantCulture);
}
