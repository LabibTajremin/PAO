using PAO.Lib.Areas.Booking;

namespace PAO.Core.Areas.Booking.Services;

/// <summary>One date of a subscription with what the apps show for it.</summary>
public sealed record DayOfSubscription(DateOnly Date, string Status, IReadOnlyList<BookingLine> Lines, Guid? BookingId, bool Changeable);

/// <summary>
/// Merges a subscription's planned dates with its stored exceptions and derives each date's
/// status (ADR-0041 §4): before the sweep from the subscription, after it from the booking.
/// </summary>
public static class SubscriptionDays
{
    /// <summary>How far ahead the apps list dates.</summary>
    public const int Horizon = 31;

    /// <summary>The dates between two days, in order.</summary>
    public static IReadOnlyList<DayOfSubscription> Between(StoredSubscription s, DateOnly first, DateOnly last, DateTimeOffset now, IReadOnlySet<DateOnly> holidays)
    {
        var planned = DeliveryCalendar.Dates(s.Plan, last, holidays).Where(d => d >= first);
        var stored = s.Dates.Keys.Where(d => d >= first && d <= last);
        return [.. planned.Union(stored).Order().Select(d => Day(s, d, now))];
    }

    /// <summary>One date as the apps show it.</summary>
    public static DayOfSubscription Day(StoredSubscription s, DateOnly date, DateTimeOffset now)
    {
        s.Dates.TryGetValue(date, out var row);
        var lines = row?.Lines ?? s.Lines;
        var open = s.Status is SubscriptionStatus.Requested or SubscriptionStatus.Active;
        var changeable = open && row?.State != DateState.Booked && row?.State != DateState.Declined
            && now < DeliveryCalendar.Cutoff(date, s.Cutoff);
        return new DayOfSubscription(date, Status(s, row, date, now), lines, row?.BookingId, changeable);
    }

    private static string Status(StoredSubscription s, SubscriptionDate? row, DateOnly date, DateTimeOffset now) => row?.State switch
    {
        DateState.Skipped => DeliveryStatus.Skipped,
        DateState.Declined => DeliveryStatus.Declined,
        DateState.Cancelled => DeliveryStatus.Cancelled,
        DateState.Booked => FromBooking(row.BookingStatus, date, now),
        _ => s.Status switch
        {
            SubscriptionStatus.Paused => DeliveryStatus.Skipped,
            SubscriptionStatus.Declined => DeliveryStatus.Declined,
            SubscriptionStatus.Cancelled => DeliveryStatus.Cancelled,
            _ => DeliveryStatus.Scheduled,
        },
    };

    /// <summary>A booked date's status from its booking.</summary>
    public static string FromBooking(string? status, DateOnly date, DateTimeOffset now) => status switch
    {
        BookingStatus.Accepted => date <= DeliveryCalendar.Today(now) ? DeliveryStatus.Preparing : DeliveryStatus.Scheduled,
        BookingStatus.OnTheWay or BookingStatus.Arrived or BookingStatus.InProgress => DeliveryStatus.OutForDelivery,
        BookingStatus.Completed => DeliveryStatus.Delivered,
        _ => DeliveryStatus.Cancelled,
    };

    /// <summary>
    /// The plan's next date at or after <paramref name="from"/> that is still to be made into a
    /// booking, or null when the plan has none left within a year.
    /// </summary>
    public static DateOnly? Next(StoredSubscription s, DateOnly from, IReadOnlySet<DateOnly> holidays) =>
        DeliveryCalendar.Dates(s.Plan, from.AddDays(366), holidays).Where(d => d >= from).Cast<DateOnly?>().FirstOrDefault();
}
