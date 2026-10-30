using PAO.Infrastructure.Data;

namespace PAO.Core.Areas.Booking.Services;

/// <summary>
/// Asia/Dhaka calendar days for the earnings screen (P-08). Dhaka is UTC+6 all year
/// (04-decisions E8), so date arithmetic never meets a time-zone change.
/// </summary>
public static class EarningsCalendar
{
    /// <summary>The Dhaka calendar date of an instant.</summary>
    public static DateOnly DhakaDay(DateTimeOffset instant) => DateOnly.FromDateTime(instant.ToOffset(DhakaTime.Offset).DateTime);

    /// <summary>The instant a Dhaka calendar date begins, in UTC as Postgres takes it.</summary>
    public static DateTimeOffset DayStart(DateOnly day) => new DateTimeOffset(day.ToDateTime(TimeOnly.MinValue), DhakaTime.Offset).ToUniversalTime();

    /// <summary>The half-open instant range [first day's start, the day after the last's start).</summary>
    public static (DateTimeOffset From, DateTimeOffset Until) Range(DateOnly from, DateOnly to) => (DayStart(from), DayStart(to.AddDays(1)));

    /// <summary>
    /// The first and last day (inclusive) of the period containing `day`; null for an
    /// unknown kind. Weeks start on Saturday, the first working day after the Friday weekend.
    /// </summary>
    public static (DateOnly From, DateOnly To)? Period(string kind, DateOnly day)
    {
        switch (kind)
        {
            case "day":
                return (day, day);
            case "week":
                var from = day.AddDays(-(((int)day.DayOfWeek + 1) % 7));
                return (from, from.AddDays(6));
            case "month":
                return Month(day);
            default:
                return null;
        }
    }

    /// <summary>The first and last day of the month containing `day`.</summary>
    public static (DateOnly From, DateOnly To) Month(DateOnly day)
    {
        var first = new DateOnly(day.Year, day.Month, 1);
        return (first, first.AddMonths(1).AddDays(-1));
    }

    /// <summary>Every date from `from` to `to` inclusive.</summary>
    public static IEnumerable<DateOnly> Days(DateOnly from, DateOnly to)
    {
        for (var d = from; d <= to; d = d.AddDays(1))
        {
            yield return d;
        }
    }

    /// <summary>The date as YYYY-MM-DD.</summary>
    public static string Iso(DateOnly day) => day.ToString("yyyy-MM-dd", System.Globalization.CultureInfo.InvariantCulture);

    /// <summary>A YYYY-MM-DD query date; the spec has already checked the format.</summary>
    public static DateOnly? Parse(string? text) =>
        text is null ? null : DateOnly.ParseExact(text, "yyyy-MM-dd", System.Globalization.CultureInfo.InvariantCulture);
}
