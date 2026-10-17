using PAO.Lib.Events;

namespace PAO.Lib.Areas.Admin;

/// <summary>The typed platform settings (A-10), defaults filled in.</summary>
public sealed record PlatformSettings
{
    public required long AcceptTimeoutAsapMs { get; init; }
    public required long AcceptTimeoutScheduledMs { get; init; }
    public required int DefaultSearchRadiusM { get; init; }
    public required double RatingFloor { get; init; }
    public required int RatingMinJobs { get; init; }
    public required int MaxProviderCancellations30d { get; init; }
    public required int StartCodeMaxAttempts { get; init; }
    public required long StartCodeLockoutMs { get; init; }
    public required long PoliceClearanceValidityMs { get; init; }
    public required long Level2CoolingOffMs { get; init; }
    public required long DocumentRetentionMs { get; init; }
    public required string ServiceAreaGeoJson { get; init; }
}

/// <summary>Names of the events the Admin area publishes.</summary>
public static class AdminEvents
{
    public const string ComplaintCreated = "admin.ComplaintCreated";
    public const string ComplaintResolved = "admin.ComplaintResolved";
    public const string SettingChanged = "admin.SettingChanged";
}

/// <summary>A party filed a complaint about a booking.</summary>
public sealed record ComplaintCreated : IDomainEvent
{
    public string Name { get; } = AdminEvents.ComplaintCreated;
    public required Guid ComplaintId { get; init; }
    public required string TicketNumber { get; init; }
    public required Guid BookingId { get; init; }
    public required Guid ReporterId { get; init; }
    public required string ReporterRole { get; init; }
    public required Guid AgainstId { get; init; }
}

/// <summary>Support resolved a complaint.</summary>
public sealed record ComplaintResolved : IDomainEvent
{
    public string Name { get; } = AdminEvents.ComplaintResolved;
    public required Guid ComplaintId { get; init; }
    public required string TicketNumber { get; init; }
    public required Guid BookingId { get; init; }
    public required Guid ReporterId { get; init; }
    public required string ReporterRole { get; init; }
    public required Guid AgainstId { get; init; }
    public required bool Verified { get; init; }
    public Guid? ActorId { get; init; }
}

/// <summary>An admin changed a setting.</summary>
public sealed record SettingChanged : IDomainEvent
{
    public string Name { get; } = AdminEvents.SettingChanged;
    public required string Key { get; init; }
    public required string Before { get; init; }
    public required string After { get; init; }
    public Guid? ActorId { get; init; }
}
