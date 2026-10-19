using PAO.EF.Admin;

namespace PAO.Lib.Areas.Admin;

/// <summary>The Admin area's error reasons; only its error map turns them into API errors.</summary>
public static class AdminReasons
{
    /// <summary>No setting has the key.</summary>
    public const string SettingNotFound = "admin.setting_not_found";
    /// <summary>The value does not match the setting's type.</summary>
    public const string SettingInvalid = "admin.setting_invalid";
    /// <summary>No complaint has the id.</summary>
    public const string ComplaintNotFound = "admin.complaint_not_found";
    /// <summary>The booking is unknown, or the caller is not its party in the reporting role.</summary>
    public const string BookingNotFound = "admin.booking_not_found";
    /// <summary>Reason, description, photo list or resolution note break the rules.</summary>
    public const string ComplaintInvalid = "admin.complaint_invalid";
    /// <summary>A photo is not the reporter's confirmed complaint photo.</summary>
    public const string PhotoInvalid = "admin.photo_invalid";
    /// <summary>The assignee is not an active support agent or super admin.</summary>
    public const string AssigneeInvalid = "admin.assignee_invalid";
    /// <summary>The complaint is already resolved.</summary>
    public const string AlreadyResolved = "admin.complaint_already_resolved";
    /// <summary>No provider or customer has the id.</summary>
    public const string PersonNotFound = "admin.person_not_found";
}

/// <summary>An internal support note on a complaint.</summary>
public sealed record ComplaintComment(Guid Id, Guid ComplaintId, Guid AuthorId, string Body, DateTimeOffset At);

/// <summary>A problem reported on a booking by either side, with its notes.</summary>
public sealed record Complaint(ComplaintRecord Row, IReadOnlyList<ComplaintComment> Comments)
{
    /// <summary>The reference shown to the reporter and support, e.g. TCK-001001.</summary>
    public string TicketNumber => Tickets.Format(Row.TicketNumber);
}

/// <summary>Ticket references.</summary>
public static class Tickets
{
    /// <summary>`TCK-` and six digits.</summary>
    public static string Format(long n) => $"TCK-{n.ToString("D6", System.Globalization.CultureInfo.InvariantCulture)}";
}

/// <summary>Narrows a page of the complaints queue, newest first.</summary>
public sealed record ComplaintFilter(string? Status, Guid? AssigneeId, DateTimeOffset? AfterAt, Guid? AfterId, int Limit);

/// <summary>One Dhaka day of bookings on the dashboard.</summary>
public sealed record DayCount(string Date, int Total, int Completed);

/// <summary>The read-model counts behind the dashboard (A-09).</summary>
public sealed record DashboardCounts(
    IReadOnlyDictionary<string, int> ProvidersByStatus, IReadOnlyDictionary<string, int> ProvidersByLevel, int OpenComplaints, IReadOnlyList<DayCount> Days);

/// <summary>An admin's decision on an account.</summary>
public sealed record StatusChange(Guid ActorId, Guid AccountId, string Status, string Reason);

/// <summary>The Admin area's request bodies: `SettingUpdate`.</summary>
public sealed record SettingUpdateInput
{
    /// <summary>The value as text.</summary>
    public string Value { get; init; } = string.Empty;
}

/// <summary>The `ComplaintInput` body (C-14).</summary>
public sealed record ComplaintInput
{
    /// <summary>The reason.</summary>
    public string Reason { get; init; } = string.Empty;
    /// <summary>The description.</summary>
    public string Description { get; init; } = string.Empty;
    /// <summary>Evidence photos.</summary>
    public IReadOnlyList<Guid>? PhotoMediaIds { get; init; }
}

/// <summary>The `ComplaintAssignInput` body.</summary>
public sealed record ComplaintAssignInput
{
    /// <summary>The admin to work it.</summary>
    public Guid AssigneeId { get; init; }
}

/// <summary>The `ComplaintCommentInput` body.</summary>
public sealed record ComplaintCommentInput
{
    /// <summary>The note.</summary>
    public string Body { get; init; } = string.Empty;
}

/// <summary>The `ComplaintResolveInput` body.</summary>
public sealed record ComplaintResolveInput
{
    /// <summary>The note.</summary>
    public string Resolution { get; init; } = string.Empty;
    /// <summary>Whether support verified it.</summary>
    public bool Verified { get; init; }
}

/// <summary>The `AccountStatusChange` body.</summary>
public sealed record AccountStatusInput
{
    /// <summary>`active`, `suspended` or `banned`.</summary>
    public string Status { get; init; } = string.Empty;
    /// <summary>Why.</summary>
    public string Reason { get; init; } = string.Empty;
}

/// <summary>The query of the admin people lists (A-05).</summary>
public sealed record PeopleQuery(string? Text, string? Status, int? Level, bool? Flagged, string? Cursor, int? Limit);

/// <summary>Text lengths as the complaint rules count them.</summary>
public static class AdminText
{
    /// <summary>Characters as Go's utf8.RuneCountInString counts them, after trimming.</summary>
    public static int Length(string text) => text.Trim().EnumerateRunes().Count();
}
