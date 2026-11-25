using PAO.Lib.Areas.Catalog;
using PAO.Lib.Common;

namespace PAO.Lib.Areas.Booking;

/// <summary>Where a scheduled-delivery subscription stands (ADR-0041 §2).</summary>
public static class SubscriptionStatus
{
    /// <summary>Waiting for the merchant.</summary>
    public const string Requested = "requested";
    /// <summary>Accepted; its dates become bookings.</summary>
    public const string Active = "active";
    /// <summary>Paused by the customer.</summary>
    public const string Paused = "paused";
    /// <summary>Its last date is past or booked.</summary>
    public const string Finished = "finished";
    /// <summary>Declined by the merchant.</summary>
    public const string Declined = "declined";
    /// <summary>Cancelled by the customer.</summary>
    public const string Cancelled = "cancelled";
}

/// <summary>The derived status of one delivery date (ADR-0041 §4).</summary>
public static class DeliveryStatus
{
    /// <summary>Not a booking yet.</summary>
    public const string Scheduled = "scheduled";
    /// <summary>A booking accepted for today.</summary>
    public const string Preparing = "preparing";
    /// <summary>The merchant is on the way or at the door.</summary>
    public const string OutForDelivery = "out_for_delivery";
    /// <summary>Completed and paid.</summary>
    public const string Delivered = "delivered";
    /// <summary>Skipped by the customer.</summary>
    public const string Skipped = "skipped";
    /// <summary>Declined by the merchant.</summary>
    public const string Declined = "declined";
    /// <summary>Cancelled with the subscription or as a booking.</summary>
    public const string Cancelled = "cancelled";
}

/// <summary>Why a date has a stored row: it differs from the plan or became a booking.</summary>
public static class DateState
{
    /// <summary>The `"skipped"` value.</summary>
    public const string Skipped = "skipped";
    /// <summary>The `"changed"` value: other quantities.</summary>
    public const string Changed = "changed";
    /// <summary>The `"declined"` value.</summary>
    public const string Declined = "declined";
    /// <summary>The `"cancelled"` value.</summary>
    public const string Cancelled = "cancelled";
    /// <summary>The `"booked"` value.</summary>
    public const string Booked = "booked";
}

/// <summary>How the dates of a subscription repeat and end.</summary>
public sealed record DeliveryPlan
{
    /// <summary>One of <see cref="DeliveryPattern"/>.</summary>
    public required string Pattern { get; init; }
    /// <summary>The days of the week, 0 Sunday to 6 Saturday, for weekdays and weekly.</summary>
    public IReadOnlyList<int> Weekdays { get; init; } = [];
    /// <summary>The day of the month for monthly.</summary>
    public int? DayOfMonth { get; init; }
    /// <summary>The first possible date.</summary>
    public required DateOnly StartDate { get; init; }
    /// <summary>The last possible date, if any.</summary>
    public DateOnly? EndDate { get; init; }
    /// <summary>How many deliveries at most, if bounded by count.</summary>
    public int? Count { get; init; }
}

/// <summary>A stored exception to the plan, with the booking's status once booked.</summary>
public sealed record SubscriptionDate(DateOnly Date, string State, IReadOnlyList<BookingLine>? Lines, Guid? BookingId, string? BookingStatus);

/// <summary>A subscription with its snapshots and its stored dates.</summary>
public sealed class StoredSubscription
{
    /// <summary>The id.</summary>
    public required Guid Id { get; init; }
    /// <summary>The number, set by the database.</summary>
    public long Number { get; set; }
    /// <summary>The customer.</summary>
    public required BookingParty Customer { get; init; }
    /// <summary>The merchant.</summary>
    public required BookingParty Provider { get; init; }
    /// <summary>The service.</summary>
    public required Guid ServiceId { get; init; }
    /// <summary>The service name.</summary>
    public required Text ServiceName { get; init; }
    /// <summary>The delivery address.</summary>
    public required AddressSnapshot Address { get; init; }
    /// <summary>The customer's note.</summary>
    public required string Note { get; init; }
    /// <summary>The priced lines of one delivery.</summary>
    public required IReadOnlyList<BookingLine> Lines { get; init; }
    /// <summary>The total of one delivery.</summary>
    public required long TotalPaisa { get; init; }
    /// <summary>What the quantity counts.</summary>
    public required string Unit { get; init; }
    /// <summary>The repeat rule.</summary>
    public required DeliveryPlan Plan { get; init; }
    /// <summary>The window.</summary>
    public required DeliveryWindow Window { get; init; }
    /// <summary>The cutoff on the day before each date.</summary>
    public required TimeOnly Cutoff { get; init; }
    /// <summary>The status.</summary>
    public required string Status { get; set; }
    /// <summary>The merchant's reason for declining.</summary>
    public string DeclineReason { get; set; } = string.Empty;
    /// <summary>The idempotency key.</summary>
    public required string IdempotencyKey { get; init; }
    /// <summary>When it was ordered.</summary>
    public required DateTimeOffset CreatedAt { get; init; }
    /// <summary>When the merchant accepted.</summary>
    public DateTimeOffset? AcceptedAt { get; set; }
    /// <summary>The stored dates, by date.</summary>
    public Dictionary<DateOnly, SubscriptionDate> Dates { get; init; } = [];

    /// <summary>The display number.</summary>
    public string Display => $"PAO-S-{Number}";
}
