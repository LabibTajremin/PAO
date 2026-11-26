using System.Globalization;
using PAO.Infrastructure.Data;
using PAO.Lib.Areas.Booking;
using PAO.Lib.Areas.Catalog;

namespace PAO.Core.Areas.Booking.Services;

/// <summary>
/// The dates of a subscription and the instants around them, in Asia/Dhaka (ADR-0041 §3).
/// Pure: the plan, the holidays and a horizon in, dates out.
/// </summary>
public static class DeliveryCalendar
{
    /// <summary>The plan's dates from its start up to <paramref name="until"/>, holidays left out and the count kept.</summary>
    public static IEnumerable<DateOnly> Dates(DeliveryPlan plan, DateOnly until, IReadOnlySet<DateOnly> holidays)
    {
        var last = plan.EndDate is { } end && end < until ? end : until;
        var left = plan.Count ?? int.MaxValue;
        foreach (var day in Candidates(plan, last))
        {
            if (left == 0)
            {
                yield break;
            }
            if (!holidays.Contains(day))
            {
                left--;
                yield return day;
            }
        }
    }

    private static IEnumerable<DateOnly> Candidates(DeliveryPlan plan, DateOnly last)
    {
        if (plan.Pattern == DeliveryPattern.Once)
        {
            return plan.StartDate <= last ? [plan.StartDate] : [];
        }
        if (plan.Pattern == DeliveryPattern.Monthly)
        {
            return Monthly(plan.StartDate, last, plan.DayOfMonth ?? plan.StartDate.Day);
        }
        var days = Enumerable.Range(0, Math.Max(0, last.DayNumber - plan.StartDate.DayNumber + 1)).Select(plan.StartDate.AddDays);
        return plan.Pattern == DeliveryPattern.Daily ? days : days.Where(d => plan.Weekdays.Contains((int)d.DayOfWeek));
    }

    private static IEnumerable<DateOnly> Monthly(DateOnly start, DateOnly last, int day)
    {
        for (var month = new DateOnly(start.Year, start.Month, 1); month <= last; month = month.AddMonths(1))
        {
            // A month without the day delivers on its last day (31 → 28 or 30).
            var date = new DateOnly(month.Year, month.Month, Math.Min(day, DateTime.DaysInMonth(month.Year, month.Month)));
            if (date >= start && date <= last)
            {
                yield return date;
            }
        }
    }

    /// <summary>Whether the plan fits the pattern rules and one of the allowed patterns.</summary>
    public static bool IsValid(DeliveryPlan plan, IReadOnlyList<string> allowed)
    {
        var weekdays = plan.Weekdays;
        var shape = plan.Pattern switch
        {
            DeliveryPattern.Once or DeliveryPattern.Daily => weekdays.Count == 0 && plan.DayOfMonth is null,
            DeliveryPattern.Weekdays => weekdays.Count is >= 1 and <= 7,
            DeliveryPattern.Weekly => weekdays.Count == 1,
            DeliveryPattern.Monthly => plan.DayOfMonth is >= 1 and <= 31 && weekdays.Count == 0,
            _ => false,
        };
        var ends = plan.EndDate is null || plan.Count is null;
        return shape && ends && allowed.Contains(plan.Pattern) && weekdays.All(d => d is >= 0 and <= 6)
            && weekdays.Distinct().Count() == weekdays.Count && (plan.EndDate is null || plan.EndDate >= plan.StartDate);
    }

    /// <summary>When changes to <paramref name="date"/> close: the cutoff on the day before.</summary>
    public static DateTimeOffset Cutoff(DateOnly date, TimeOnly cutoff) => At(date.AddDays(-1), cutoff);

    /// <summary>A Dhaka date and time as an instant.</summary>
    public static DateTimeOffset At(DateOnly date, TimeOnly time) =>
        new DateTimeOffset(date.ToDateTime(time), DhakaTime.Offset).ToUniversalTime();

    /// <summary>The Dhaka date of an instant.</summary>
    public static DateOnly Today(DateTimeOffset now) => EarningsCalendar.DhakaDay(now);

    /// <summary>The holiday setting's dates; unreadable entries are ignored.</summary>
    public static IReadOnlySet<DateOnly> Holidays(string text) => text
        .Split(',', StringSplitOptions.TrimEntries | StringSplitOptions.RemoveEmptyEntries)
        .Select(d => DateOnly.TryParseExact(d, "yyyy-MM-dd", CultureInfo.InvariantCulture, DateTimeStyles.None, out var day) ? day : (DateOnly?)null)
        .OfType<DateOnly>()
        .ToHashSet();

    /// <summary>The window as the apps print it, e.g. 12:00–13:00.</summary>
    public static string Label(DeliveryWindow window) => $"{window.Start}–{window.End}";
}
