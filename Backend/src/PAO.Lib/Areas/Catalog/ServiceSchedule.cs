using System.Globalization;

namespace PAO.Lib.Areas.Catalog;

/// <summary>How the dates of a scheduled delivery repeat (ADR-0041).</summary>
public static class DeliveryPattern
{
    /// <summary>The `"once"` value: one date.</summary>
    public const string Once = "once";
    /// <summary>The `"daily"` value.</summary>
    public const string Daily = "daily";
    /// <summary>The `"weekdays"` value: the chosen days of every week.</summary>
    public const string Weekdays = "weekdays";
    /// <summary>The `"weekly"` value: one chosen day of every week.</summary>
    public const string Weekly = "weekly";
    /// <summary>The `"monthly"` value: one day of every month.</summary>
    public const string Monthly = "monthly";

    /// <summary>Every pattern.</summary>
    public static readonly IReadOnlyList<string> All = [Once, Daily, Weekdays, Weekly, Monthly];
}

/// <summary>What the quantity of a scheduled delivery counts.</summary>
public static class QuantityUnit
{
    /// <summary>Every unit: meals, guests and packages.</summary>
    public static readonly IReadOnlyList<string> All = ["meals", "guests", "package"];
}

/// <summary>A delivery window in Asia/Dhaka time, as "HH:mm".</summary>
public sealed record DeliveryWindow
{
    /// <summary>The start.</summary>
    public required string Start { get; init; }
    /// <summary>The end.</summary>
    public required string End { get; init; }

    /// <summary>The start as a time of day.</summary>
    public TimeOnly From => ScheduleTime.Parse(Start)!.Value;

    /// <summary>The end as a time of day.</summary>
    public TimeOnly To => ScheduleTime.Parse(End)!.Value;

    /// <summary>Whether both ends are times and the window has length.</summary>
    public bool IsValid => ScheduleTime.Parse(Start) is { } from && ScheduleTime.Parse(End) is { } to && from < to;
}

/// <summary>The ordering rules of a scheduled-delivery service, set by the admin (ADR-0041 §1).</summary>
public sealed record ServiceSchedule
{
    /// <summary>The patterns a customer may choose.</summary>
    public required IReadOnlyList<string> Patterns { get; init; }
    /// <summary>The windows a customer may choose.</summary>
    public required IReadOnlyList<DeliveryWindow> Windows { get; init; }
    /// <summary>The minimum hours between ordering and the first delivery.</summary>
    public required int LeadHours { get; init; }
    /// <summary>The time on the day before a date when its orders and changes close.</summary>
    public required string Cutoff { get; init; }
    /// <summary>What the quantity counts.</summary>
    public required string Unit { get; init; }
    /// <summary>The smallest quantity per delivery.</summary>
    public required int MinQuantity { get; init; }
    /// <summary>The largest quantity per delivery.</summary>
    public required int MaxQuantity { get; init; }

    /// <summary>The cutoff as a time of day.</summary>
    public TimeOnly CutoffTime => ScheduleTime.Parse(Cutoff)!.Value;

    /// <summary>Whether every rule is in range, as the contract allows.</summary>
    public bool IsValid =>
        Patterns.Count is >= 1 and <= 5 && Patterns.Distinct().Count() == Patterns.Count && Patterns.All(DeliveryPattern.All.Contains)
        && Windows.Count is >= 1 and <= 8 && Windows.All(w => w.IsValid)
        && LeadHours is >= 0 and <= 336 && ScheduleTime.Parse(Cutoff) is not null && QuantityUnit.All.Contains(Unit)
        && MinQuantity is >= 1 and <= 500 && MaxQuantity is >= 1 and <= 500 && MinQuantity <= MaxQuantity;
}

/// <summary>Reads the "HH:mm" times of a schedule.</summary>
public static class ScheduleTime
{
    /// <summary>The time, or null when the text is not "HH:mm".</summary>
    public static TimeOnly? Parse(string? text) =>
        text is { Length: 5 } && TimeOnly.TryParseExact(text, "HH:mm", CultureInfo.InvariantCulture, DateTimeStyles.None, out var time) ? time : null;
}
