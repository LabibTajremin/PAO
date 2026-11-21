using System.Text.Json.Serialization;
using PAO.Lib.Areas.Audit;
using PAO.Lib.Areas.Verification;
using PAO.Lib.Common;

namespace PAO.Lib.Areas.Admin;

/// <summary>The spec's `Setting`.</summary>
public sealed record SettingView
{
    /// <summary>The key.</summary>
    public required string Key { get; init; }
    /// <summary>The value as text.</summary>
    public required string Value { get; init; }
    /// <summary>How to read it.</summary>
    public required string Type { get; init; }
    /// <summary>What it does.</summary>
    public required string Description { get; init; }
    /// <summary>When it changed.</summary>
    public required string UpdatedAt { get; init; }
    /// <summary>Who changed it.</summary>
    [JsonIgnore(Condition = JsonIgnoreCondition.WhenWritingNull)]
    public Guid? UpdatedBy { get; init; }
}

/// <summary>The spec's `SettingList`.</summary>
public sealed record SettingListView
{
    /// <summary>Every setting by key.</summary>
    public required IReadOnlyList<SettingView> Items { get; init; }
}

/// <summary>The spec's `ComplaintComment`.</summary>
public sealed record ComplaintCommentView
{
    /// <summary>The author.</summary>
    public required Guid AuthorId { get; init; }
    /// <summary>The note.</summary>
    public required string Body { get; init; }
    /// <summary>When.</summary>
    public required string At { get; init; }
}

/// <summary>The spec's `Complaint`.</summary>
public sealed record ComplaintView
{
    /// <summary>The id.</summary>
    public required Guid Id { get; init; }
    /// <summary>The ticket.</summary>
    public required string TicketNumber { get; init; }
    /// <summary>The booking.</summary>
    public required Guid BookingId { get; init; }
    /// <summary>The reporter's role.</summary>
    public required string ReporterRole { get; init; }
    /// <summary>The reporter.</summary>
    public required Guid ReporterId { get; init; }
    /// <summary>The other party.</summary>
    public required Guid AgainstId { get; init; }
    /// <summary>The reason.</summary>
    public required string Reason { get; init; }
    /// <summary>The description.</summary>
    public required string Description { get; init; }
    /// <summary>Evidence photos.</summary>
    public required IReadOnlyList<Guid> PhotoMediaIds { get; init; }
    /// <summary>The status.</summary>
    public required string Status { get; init; }
    /// <summary>Who works it.</summary>
    [JsonIgnore(Condition = JsonIgnoreCondition.WhenWritingNull)]
    public Guid? AssigneeId { get; init; }
    /// <summary>The resolution note.</summary>
    public required string Resolution { get; init; }
    /// <summary>Whether verified.</summary>
    public required bool Verified { get; init; }
    /// <summary>Support notes.</summary>
    public required IReadOnlyList<ComplaintCommentView> Comments { get; init; }
    /// <summary>When filed.</summary>
    public required string CreatedAt { get; init; }
    /// <summary>When resolved.</summary>
    [JsonIgnore(Condition = JsonIgnoreCondition.WhenWritingNull)]
    public string? ResolvedAt { get; init; }
}

/// <summary>A page of admin rows (`ComplaintList`, `AdminProviderList`, `AdminCustomerList`).</summary>
public sealed record PageView<T>
{
    /// <summary>The rows.</summary>
    public required IReadOnlyList<T> Items { get; init; }
    /// <summary>The cursor of the next page.</summary>
    [JsonIgnore(Condition = JsonIgnoreCondition.WhenWritingNull)]
    public string? NextCursor { get; init; }
}

/// <summary>One day of the spec's `Dashboard`.</summary>
public sealed record DayCountView
{
    /// <summary>The Dhaka date.</summary>
    public required string Date { get; init; }
    /// <summary>Requests.</summary>
    public required int Total { get; init; }
    /// <summary>Completions.</summary>
    public required int Completed { get; init; }
}

/// <summary>The spec's `Dashboard` (A-09); also the cached copy.</summary>
public sealed record DashboardView
{
    /// <summary>Providers per status.</summary>
    public required IReadOnlyDictionary<string, int> ProvidersByStatus { get; init; }
    /// <summary>Providers per level.</summary>
    public required IReadOnlyDictionary<string, int> ProvidersByLevel { get; init; }
    /// <summary>The last 30 days.</summary>
    public required IReadOnlyList<DayCountView> BookingsPerDay { get; init; }
    /// <summary>Completed over requested, two decimals.</summary>
    public required double CompletionRate { get; init; }
    /// <summary>Unresolved complaints.</summary>
    public required int OpenComplaints { get; init; }
    /// <summary>Merchants awaiting review.</summary>
    public required int PendingVerifications { get; init; }
    /// <summary>When the numbers were built.</summary>
    public required string GeneratedAt { get; init; }
}

/// <summary>The spec's `AdminProviderSummary`.</summary>
public sealed record AdminProviderSummaryView
{
    /// <summary>The id.</summary>
    public required Guid Id { get; init; }
    /// <summary>The name.</summary>
    public required string Name { get; init; }
    /// <summary>The phone.</summary>
    public required string Phone { get; init; }
    /// <summary>The status.</summary>
    public required string Status { get; init; }
    /// <summary>The level.</summary>
    public required int Level { get; init; }
    /// <summary>Services offered.</summary>
    public required IReadOnlyList<ServiceRefView> Services { get; init; }
    /// <summary>The average rating.</summary>
    public required double Rating { get; init; }
    /// <summary>Completed jobs.</summary>
    public required int CompletedJobs { get; init; }
    /// <summary>Whether a threshold flagged them.</summary>
    public required bool FlaggedForReview { get; init; }
    /// <summary>Whether online.</summary>
    public required bool Online { get; init; }
    /// <summary>When they joined.</summary>
    public required string CreatedAt { get; init; }
}

/// <summary>The spec's `BookingSummary` on admin detail pages.</summary>
public sealed record RecentBookingView
{
    /// <summary>The id.</summary>
    public required Guid Id { get; init; }
    /// <summary>The number.</summary>
    public required string Number { get; init; }
    /// <summary>The status.</summary>
    public required string Status { get; init; }
    /// <summary>The service name.</summary>
    public required Text ServiceName { get; init; }
    /// <summary>The bill.</summary>
    public required long Total { get; init; }
    /// <summary>When requested.</summary>
    public required string CreatedAt { get; init; }
}

/// <summary>The spec's `AdminProviderDetail`.</summary>
public sealed record AdminProviderDetailView
{
    /// <summary>The list row.</summary>
    public required AdminProviderSummaryView Summary { get; init; }
    /// <summary>The gender.</summary>
    [JsonIgnore(Condition = JsonIgnoreCondition.WhenWritingNull)]
    public string? Gender { get; init; }
    /// <summary>Years of experience.</summary>
    public required int ExperienceYears { get; init; }
    /// <summary>Verification items.</summary>
    public required IReadOnlyList<VerificationItemView> Items { get; init; }
    /// <summary>Latest bookings.</summary>
    public required IReadOnlyList<RecentBookingView> RecentBookings { get; init; }
    /// <summary>Complaints against them.</summary>
    public required int Complaints { get; init; }
    /// <summary>Cancellations after acceptance in 30 days.</summary>
    public required int Cancellations30d { get; init; }
    /// <summary>Status changes.</summary>
    public required IReadOnlyList<AuditEntryView> StatusHistory { get; init; }
}

/// <summary>The spec's `AdminCustomerSummary`; the rating once providers rated them.</summary>
public sealed record AdminCustomerSummaryView
{
    /// <summary>The id.</summary>
    public required Guid Id { get; init; }
    /// <summary>The name.</summary>
    public required string Name { get; init; }
    /// <summary>The phone.</summary>
    public required string Phone { get; init; }
    /// <summary>The status.</summary>
    public required string Status { get; init; }
    /// <summary>Bookings made.</summary>
    public required int Bookings { get; init; }
    /// <summary>When they joined.</summary>
    public required string CreatedAt { get; init; }
    /// <summary>The average rating.</summary>
    [JsonIgnore(Condition = JsonIgnoreCondition.WhenWritingNull)]
    public double? Rating { get; init; }
}

/// <summary>The spec's `AdminCustomerDetail`.</summary>
public sealed record AdminCustomerDetailView
{
    /// <summary>The list row.</summary>
    public required AdminCustomerSummaryView Summary { get; init; }
    /// <summary>Latest bookings.</summary>
    public required IReadOnlyList<RecentBookingView> RecentBookings { get; init; }
    /// <summary>Complaints they filed or received.</summary>
    public required IReadOnlyList<ComplaintView> Complaints { get; init; }
    /// <summary>Status changes.</summary>
    public required IReadOnlyList<AuditEntryView> StatusHistory { get; init; }
}
