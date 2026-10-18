using System.Text.Json.Serialization;
using PAO.Lib.Common;

namespace PAO.Lib.Areas.Verification;

/// <summary>One step of the enrolment wizard.</summary>
public sealed record StepStatusView
{
    /// <summary>The step.</summary>
    public required string Step { get; init; }
    /// <summary>Whether it is done.</summary>
    public required bool Done { get; init; }
    /// <summary>Whether Level 1 needs it.</summary>
    public required bool Required { get; init; }
}

/// <summary>The API shape of `EnrolmentStatus`, answered by every document step.</summary>
public sealed record EnrolmentStatusView
{
    /// <summary>The steps.</summary>
    public required IReadOnlyList<StepStatusView> Steps { get; init; }
    /// <summary>Every required step is done.</summary>
    public required bool Complete { get; init; }
    /// <summary>The enrolment was sent for review.</summary>
    public required bool Submitted { get; init; }
}

/// <summary>The API shape of `VerificationItem`.</summary>
public record VerificationItemView
{
    /// <summary>The item type.</summary>
    public required string Type { get; init; }
    /// <summary>The status.</summary>
    public required string Status { get; init; }
    /// <summary>Whether Level 1 needs it.</summary>
    public required bool Required { get; init; }
    /// <summary>The rejection reason.</summary>
    [JsonIgnore(Condition = JsonIgnoreCondition.WhenWritingNull)]
    public string? RejectionReason { get; init; }
    /// <summary>When it was decided (ISO 8601).</summary>
    [JsonIgnore(Condition = JsonIgnoreCondition.WhenWritingNull)]
    public string? DecidedAt { get; init; }
    /// <summary>When the approval stops counting (ISO 8601).</summary>
    [JsonIgnore(Condition = JsonIgnoreCondition.WhenWritingNull)]
    public string? ExpiresAt { get; init; }
}

/// <summary>The API shape of `Level2Session`; the result details appear once it has one.</summary>
public sealed record Level2SessionView
{
    /// <summary>The id.</summary>
    public required Guid Id { get; init; }
    /// <summary>The merchant.</summary>
    public required Guid ProviderId { get; init; }
    /// <summary>The service.</summary>
    public required Guid ServiceId { get; init; }
    /// <summary>When (ISO 8601).</summary>
    public required string ScheduledAt { get; init; }
    /// <summary>Where.</summary>
    public required string Location { get; init; }
    /// <summary>The status.</summary>
    public required string Status { get; init; }
    /// <summary>The verifier who recorded the result.</summary>
    [JsonIgnore(Condition = JsonIgnoreCondition.WhenWritingNull)]
    public Guid? DecidedBy { get; init; }
    /// <summary>The result.</summary>
    [JsonIgnore(Condition = JsonIgnoreCondition.WhenWritingNull)]
    public string? Result { get; init; }
    /// <summary>The notes.</summary>
    [JsonIgnore(Condition = JsonIgnoreCondition.WhenWritingNull)]
    public string? Notes { get; init; }
    /// <summary>The checklist.</summary>
    [JsonIgnore(Condition = JsonIgnoreCondition.WhenWritingNull)]
    public IReadOnlyList<CheckItem>? Checklist { get; init; }
}

/// <summary>The API shape of `Level2SessionList`.</summary>
public sealed record Level2SessionListView
{
    /// <summary>The sessions, newest first.</summary>
    public required IReadOnlyList<Level2SessionView> Items { get; init; }
    /// <summary>The next page, when there is one.</summary>
    [JsonIgnore(Condition = JsonIgnoreCondition.WhenWritingNull)]
    public string? NextCursor { get; init; }
}

/// <summary>The API shape of `Level2Info`.</summary>
public sealed record Level2InfoView
{
    /// <summary>Whether a session may be booked now.</summary>
    public required bool Eligible { get; init; }
    /// <summary>The booked session.</summary>
    [JsonIgnore(Condition = JsonIgnoreCondition.WhenWritingNull)]
    public Level2SessionView? NextSession { get; init; }
    /// <summary>The end of the cooling-off period (ISO 8601).</summary>
    [JsonIgnore(Condition = JsonIgnoreCondition.WhenWritingNull)]
    public string? RetryAfter { get; init; }
}

/// <summary>The API shape of `VerificationStatus` (M14/P-03).</summary>
public sealed record VerificationStatusView
{
    /// <summary>The level.</summary>
    public required int Level { get; init; }
    /// <summary>`none`, `verified` or `verified_pro`.</summary>
    public required string Badge { get; init; }
    /// <summary>Every item in display order.</summary>
    public required IReadOnlyList<VerificationItemView> Items { get; init; }
    /// <summary>Whether bookings may arrive.</summary>
    public required bool CanReceiveBookings { get; init; }
    /// <summary>The Level 2 situation.</summary>
    public required Level2InfoView Level2 { get; init; }
}

/// <summary>The API shape of `ServiceRef`.</summary>
public sealed record ServiceRefView
{
    /// <summary>The id.</summary>
    public required Guid Id { get; init; }
    /// <summary>The name.</summary>
    public required Text Name { get; init; }
}

/// <summary>The API shape of `VerificationQueueItem` (A-03).</summary>
public sealed record VerificationQueueItemView
{
    /// <summary>The merchant.</summary>
    public required Guid ProviderId { get; init; }
    /// <summary>The merchant's name.</summary>
    public required string Name { get; init; }
    /// <summary>Items waiting for a decision.</summary>
    public required IReadOnlyList<string> PendingItems { get; init; }
    /// <summary>When the enrolment was submitted (ISO 8601).</summary>
    public required string SubmittedAt { get; init; }
    /// <summary>Whole hours waiting.</summary>
    public required long AgeHours { get; init; }
    /// <summary>The services offered.</summary>
    public required IReadOnlyList<ServiceRefView> Services { get; init; }
}

/// <summary>The API shape of `VerificationQueue`.</summary>
public sealed record VerificationQueueView
{
    /// <summary>The rows, oldest submission first.</summary>
    public required IReadOnlyList<VerificationQueueItemView> Items { get; init; }
    /// <summary>The next page, when there is one.</summary>
    [JsonIgnore(Condition = JsonIgnoreCondition.WhenWritingNull)]
    public string? NextCursor { get; init; }
}

/// <summary>The API shape of `ReviewDocument`.</summary>
public sealed record ReviewDocumentView
{
    /// <summary>The media object.</summary>
    public required Guid MediaId { get; init; }
    /// <summary>The kind.</summary>
    public required string Kind { get; init; }
}

/// <summary>The API shape of `ReviewItem`: an item with its files and the values to check.</summary>
public sealed record ReviewItemView : VerificationItemView
{
    /// <summary>The current files.</summary>
    public required IReadOnlyList<ReviewDocumentView> Documents { get; init; }
    /// <summary>Submitted and profile values to check.</summary>
    public required IReadOnlyDictionary<string, string> Fields { get; init; }
}

/// <summary>The profile part of `VerificationReview`.</summary>
public sealed record ReviewProfileView
{
    /// <summary>The full name.</summary>
    public required string FullName { get; init; }
    /// <summary>The birth date (`0001-01-01` when never saved, as Go wrote it).</summary>
    public required string DateOfBirth { get; init; }
    /// <summary>The gender.</summary>
    public required string Gender { get; init; }
    /// <summary>The phone.</summary>
    public required string Phone { get; init; }
    /// <summary>The present address.</summary>
    public required string PresentAddress { get; init; }
    /// <summary>The permanent address.</summary>
    public required string PermanentAddress { get; init; }
    /// <summary>The decrypted NID number; only this screen shows it.</summary>
    [JsonIgnore(Condition = JsonIgnoreCondition.WhenWritingNull)]
    public string? NidNumber { get; init; }
}

/// <summary>The API shape of `VerificationReview` (A06).</summary>
public sealed record VerificationReviewView
{
    /// <summary>The merchant.</summary>
    public required Guid ProviderId { get; init; }
    /// <summary>The level.</summary>
    public required int Level { get; init; }
    /// <summary>The profile.</summary>
    public required ReviewProfileView Profile { get; init; }
    /// <summary>`manual_review` once a selfie was sent, `not_run` before (D10).</summary>
    public required string FaceMatch { get; init; }
    /// <summary>Every item in display order.</summary>
    public required IReadOnlyList<ReviewItemView> Items { get; init; }
}
