using PAO.Infrastructure.Events;
using PAO.Lib.Areas.Booking;
using PAO.Lib.Areas.Notification;

namespace PAO.Core.Areas.Notification.Services;

/// <summary>
/// Who hears about each subscription event (ADR-0041 §6). The events carry the number and
/// the service names, so these notes need no read back.
/// </summary>
public static class SubscriptionNotes
{
    /// <summary>The recipients of each subscription event, by event name.</summary>
    public static readonly IReadOnlyDictionary<string, Func<EventPayload, IReadOnlyList<Note>>> Recipients =
        new Dictionary<string, Func<EventPayload, IReadOnlyList<Note>>>(StringComparer.Ordinal)
        {
            [SubscriptionEvents.SubscriptionRequested] = p => [Provider(p, "subscription_requested", ("date", p.Text("startDate")))],
            [SubscriptionEvents.SubscriptionAccepted] = p => [Customer(p, "subscription_accepted")],
            [SubscriptionEvents.SubscriptionDeclined] = p => [Customer(p, "subscription_declined")],
            [SubscriptionEvents.SubscriptionChanged] = p => [Provider(p, "subscription_changed", ("status", p.Text("status")))],
            [SubscriptionEvents.DeliveryDateChanged] = p => [Provider(p, "delivery_changed", ("date", p.Text("date")))],
            [SubscriptionEvents.DeliveryDeclined] = p => [Customer(p, "delivery_declined", ("date", p.Text("date")))],
        };

    private static Note Customer(EventPayload p, string template, params (string Key, string Value)[] extra) =>
        new(p.Id("customerId"), NotificationApp.Customer, template) { Extra = extra.ToDictionary(e => e.Key, e => e.Value) };

    private static Note Provider(EventPayload p, string template, params (string Key, string Value)[] extra) =>
        new(p.Id("providerId"), NotificationApp.Partner, template) { Extra = extra.ToDictionary(e => e.Key, e => e.Value) };
}
