using PAO.Lib.Events;
using PAO.Lib.Mediator;

namespace PAO.Lib.Areas.Booking;

/// <summary>Names of the scheduled-delivery events (ADR-0041).</summary>
public static class SubscriptionEvents
{
    /// <summary>The `"booking.SubscriptionRequested"` value.</summary>
    public const string SubscriptionRequested = "booking.SubscriptionRequested";
    /// <summary>The `"booking.SubscriptionAccepted"` value.</summary>
    public const string SubscriptionAccepted = "booking.SubscriptionAccepted";
    /// <summary>The `"booking.SubscriptionDeclined"` value.</summary>
    public const string SubscriptionDeclined = "booking.SubscriptionDeclined";
    /// <summary>The `"booking.SubscriptionChanged"` value: paused, resumed or cancelled.</summary>
    public const string SubscriptionChanged = "booking.SubscriptionChanged";
    /// <summary>The `"booking.DeliveryDateChanged"` value: the customer skipped or changed a date.</summary>
    public const string DeliveryDateChanged = "booking.DeliveryDateChanged";
    /// <summary>The `"booking.DeliveryDeclined"` value: the merchant declined a date.</summary>
    public const string DeliveryDeclined = "booking.DeliveryDeclined";
    /// <summary>The `"booking.DeliveryBooked"` value: the cutoff sweep made a date into a booking.</summary>
    public const string DeliveryBooked = "booking.DeliveryBooked";
}

/// <summary>The fields every subscription event carries, so notifications need no read back.</summary>
public abstract record SubscriptionEvent(string Name) : IDomainEvent
{
    /// <summary>The subscription id.</summary>
    public Guid SubscriptionId { get; init; }
    /// <summary>The number, e.g. PAO-S-500001.</summary>
    public string Number { get; init; } = string.Empty;
    /// <summary>The customer id.</summary>
    public Guid CustomerId { get; init; }
    /// <summary>The merchant id.</summary>
    public Guid ProviderId { get; init; }
    /// <summary>The service id.</summary>
    public Guid ServiceId { get; init; }
    /// <summary>The service name in English.</summary>
    public string ServiceEn { get; init; } = string.Empty;
    /// <summary>The service name in Bangla.</summary>
    public string ServiceBn { get; init; } = string.Empty;
    /// <summary>When the change happened (ISO 8601).</summary>
    public string At { get; init; } = string.Empty;
}

/// <summary>A customer ordered a subscription.</summary>
public sealed record SubscriptionRequested() : SubscriptionEvent(SubscriptionEvents.SubscriptionRequested)
{
    /// <summary>The first date.</summary>
    public required string StartDate { get; init; }
}

/// <summary>The merchant accepted a subscription.</summary>
public sealed record SubscriptionAccepted() : SubscriptionEvent(SubscriptionEvents.SubscriptionAccepted);

/// <summary>The merchant declined a subscription.</summary>
public sealed record SubscriptionDeclined() : SubscriptionEvent(SubscriptionEvents.SubscriptionDeclined)
{
    /// <summary>The reason.</summary>
    public required string Reason { get; init; }
}

/// <summary>The customer paused, resumed or cancelled a subscription.</summary>
public sealed record SubscriptionChanged() : SubscriptionEvent(SubscriptionEvents.SubscriptionChanged)
{
    /// <summary>The new status.</summary>
    public required string Status { get; init; }
}

/// <summary>The customer skipped, brought back or changed one date.</summary>
public sealed record DeliveryDateChanged() : SubscriptionEvent(SubscriptionEvents.DeliveryDateChanged)
{
    /// <summary>The date.</summary>
    public required string Date { get; init; }
    /// <summary>Whether the date is now skipped.</summary>
    public required bool Skipped { get; init; }
}

/// <summary>The merchant declined one date.</summary>
public sealed record DeliveryDeclined() : SubscriptionEvent(SubscriptionEvents.DeliveryDeclined)
{
    /// <summary>The date.</summary>
    public required string Date { get; init; }
}

/// <summary>The cutoff sweep made a date into an accepted booking; tomorrow's reminder.</summary>
public sealed record DeliveryBooked() : BookingEvent(SubscriptionEvents.DeliveryBooked)
{
    /// <summary>The subscription.</summary>
    public required Guid SubscriptionId { get; init; }
    /// <summary>The date.</summary>
    public required string Date { get; init; }
    /// <summary>The window, e.g. 12:00–13:00.</summary>
    public required string Window { get; init; }
}

/// <summary>
/// The cutoff sweep (ADR-0041 §4): every active subscription's dates whose cutoff passed and
/// whose window has not ended become accepted bookings, today's and tomorrow's only. Each
/// booking writes in its own transaction with a key per date, so a rerun after a failure
/// finds the booking instead of making a second one. Returns how many it made; `At`
/// decides what is due at another time, for the `/__test/booking/deliveries` hook.
/// </summary>
public sealed record MaterialiseDeliveries(DateTimeOffset? At = null) : IRequest<int>;
