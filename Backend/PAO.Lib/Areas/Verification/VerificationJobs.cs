using PAO.Lib.Mediator;

namespace PAO.Lib.Areas.Verification;

/// <summary>
/// Expires approved items whose validity ended by `At` (the clock when null); levels drop
/// and `DocumentExpired` follows (PRD §6.4). Returns how many merchants changed.
/// </summary>
public sealed record ExpireDocuments(DateTimeOffset? At = null) : ICommand<int>;

/// <summary>Sends each 30, 7 and 1 day expiry reminder once (P-11). Returns how many were sent.</summary>
public sealed record RemindExpiringDocuments : ICommand<int>;

/// <summary>Purges the records and files of accounts closed longer than the retention period (ADR-0023). Returns how many.</summary>
public sealed record PurgeClosedAccounts : ICommand<int>;

/// <summary>
/// The calendar rules that use the Dhaka date (04-decisions E8): Asia/Dhaka is UTC+6 with no
/// daylight saving, and dates people type ("YYYY-MM-DD") are Dhaka dates.
/// </summary>
public static class DhakaDates
{
    private static readonly TimeSpan Offset = TimeSpan.FromHours(6);

    /// <summary>The calendar date in Dhaka at `now`.</summary>
    public static DateOnly Today(DateTimeOffset now) => DateOnly.FromDateTime(now.ToOffset(Offset).DateTime);

    /// <summary>
    /// The 18th birthday. Someone born on 29 February turns 18 on 1 March in a common year,
    /// as JavaScript's `setUTCFullYear` rolled it, so both backends agree.
    /// </summary>
    public static DateOnly EighteenthBirthday(DateOnly born)
    {
        var year = born.Year + 18;
        return born is { Month: 2, Day: 29 } && !DateTime.IsLeapYear(year) ? new DateOnly(year, 3, 1) : new DateOnly(year, born.Month, born.Day);
    }

    /// <summary>Whether someone born on `born` is 18 on the Dhaka date `today`.</summary>
    public static bool IsAdult(DateOnly born, DateOnly today) => EighteenthBirthday(born) <= today;
}
