using PAO.Lib.Events;

namespace PAO.Lib.Areas.Admin;

/// <summary>The typed platform settings (A-10), defaults filled in.</summary>
public sealed record PlatformSettings
{
    /// <summary>The accept timeout asap milliseconds.</summary>
    public required long AcceptTimeoutAsapMs { get; init; }
    /// <summary>The accept timeout scheduled milliseconds.</summary>
    public required long AcceptTimeoutScheduledMs { get; init; }
    /// <summary>The default search radius m.</summary>
    public required int DefaultSearchRadiusM { get; init; }
    /// <summary>The rating floor.</summary>
    public required double RatingFloor { get; init; }
    /// <summary>The rating min jobs.</summary>
    public required int RatingMinJobs { get; init; }
    /// <summary>The max provider cancellations 30d.</summary>
    public required int MaxProviderCancellations30d { get; init; }
    /// <summary>The start code max attempts.</summary>
    public required int StartCodeMaxAttempts { get; init; }
    /// <summary>The start code lockout milliseconds.</summary>
    public required long StartCodeLockoutMs { get; init; }
    /// <summary>The police clearance validity milliseconds.</summary>
    public required long PoliceClearanceValidityMs { get; init; }
    /// <summary>The level 2 cooling off milliseconds.</summary>
    public required long Level2CoolingOffMs { get; init; }
    /// <summary>The document retention milliseconds.</summary>
    public required long DocumentRetentionMs { get; init; }
    /// <summary>The service area geo json.</summary>
    public required string ServiceAreaGeoJson { get; init; }
    /// <summary>PAO commission on a completed job in basis points (ADR-0035 §2).</summary>
    public int CommissionRateBp { get; init; } = 1000;
    /// <summary>The due in paisa above which a merchant cannot accept (ADR-0035 §3).</summary>
    public long DueBlockAmountPaisa { get; init; } = 50_000;
}

/// <summary>Names of the events the Admin area publishes.</summary>
public static class AdminEvents
{
    /// <summary>The `"admin.ComplaintCreated"` value.</summary>
    public const string ComplaintCreated = "admin.ComplaintCreated";
    /// <summary>The `"admin.ComplaintResolved"` value.</summary>
    public const string ComplaintResolved = "admin.ComplaintResolved";
    /// <summary>The `"admin.SettingChanged"` value.</summary>
    public const string SettingChanged = "admin.SettingChanged";
}

/// <summary>A party filed a complaint about a booking.</summary>
public sealed record ComplaintCreated : IDomainEvent
{
    /// <summary>The name.</summary>
    public string Name { get; } = AdminEvents.ComplaintCreated;
    /// <summary>The complaint id.</summary>
    public required Guid ComplaintId { get; init; }
    /// <summary>The ticket number.</summary>
    public required string TicketNumber { get; init; }
    /// <summary>The booking id.</summary>
    public required Guid BookingId { get; init; }
    /// <summary>The reporter id.</summary>
    public required Guid ReporterId { get; init; }
    /// <summary>The reporter role.</summary>
    public required string ReporterRole { get; init; }
    /// <summary>The against id.</summary>
    public required Guid AgainstId { get; init; }
}

/// <summary>Support resolved a complaint.</summary>
public sealed record ComplaintResolved : IDomainEvent
{
    /// <summary>The name.</summary>
    public string Name { get; } = AdminEvents.ComplaintResolved;
    /// <summary>The complaint id.</summary>
    public required Guid ComplaintId { get; init; }
    /// <summary>The ticket number.</summary>
    public required string TicketNumber { get; init; }
    /// <summary>The booking id.</summary>
    public required Guid BookingId { get; init; }
    /// <summary>The reporter id.</summary>
    public required Guid ReporterId { get; init; }
    /// <summary>The reporter role.</summary>
    public required string ReporterRole { get; init; }
    /// <summary>The against id.</summary>
    public required Guid AgainstId { get; init; }
    /// <summary>Whether verified.</summary>
    public required bool Verified { get; init; }
    /// <summary>The actor id.</summary>
    public Guid? ActorId { get; init; }
}

/// <summary>An admin changed a setting.</summary>
public sealed record SettingChanged : IDomainEvent
{
    /// <summary>The name.</summary>
    public string Name { get; } = AdminEvents.SettingChanged;
    /// <summary>The key.</summary>
    public required string Key { get; init; }
    /// <summary>The before.</summary>
    public required string Before { get; init; }
    /// <summary>The after.</summary>
    public required string After { get; init; }
    /// <summary>The actor id.</summary>
    public Guid? ActorId { get; init; }
}
