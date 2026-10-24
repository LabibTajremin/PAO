namespace PAO.EF.Verification;

/// <summary>A row of `verification.items`: one Level 1 requirement of a merchant and its review state.</summary>
public sealed class VerificationItemRecord
{
    /// <summary>The merchant.</summary>
    public Guid ProviderId { get; set; }
    /// <summary>The item type, e.g. `nid`.</summary>
    public required string ItemType { get; set; }
    /// <summary>`missing`, `pending`, `approved`, `rejected` or `expired`.</summary>
    public required string Status { get; set; }
    /// <summary>The verifier's reason for a rejection; empty otherwise.</summary>
    public required string RejectionReason { get; set; }
    /// <summary>Submitted values as a JSON object of strings.</summary>
    public required string Fields { get; set; }
    /// <summary>When the item was last submitted.</summary>
    public DateTimeOffset? SubmittedAt { get; set; }
    /// <summary>When a verifier decided it.</summary>
    public DateTimeOffset? DecidedAt { get; set; }
    /// <summary>The deciding verifier.</summary>
    public Guid? DecidedBy { get; set; }
    /// <summary>When the approval stops counting.</summary>
    public DateTimeOffset? ExpiresAt { get; set; }
}

/// <summary>A row of `verification.documents`: an uploaded file attached to an item.</summary>
public sealed class VerificationDocumentRecord
{
    /// <summary>The id.</summary>
    public Guid Id { get; set; }
    /// <summary>The merchant.</summary>
    public Guid ProviderId { get; set; }
    /// <summary>The item the file belongs to.</summary>
    public required string ItemType { get; set; }
    /// <summary>The kind, e.g. `nid_front`.</summary>
    public required string Kind { get; set; }
    /// <summary>The media object.</summary>
    public Guid MediaId { get; set; }
    /// <summary>False once a newer submission of the item replaced it.</summary>
    public bool Current { get; set; }
    /// <summary>When it was attached.</summary>
    public DateTimeOffset CreatedAt { get; set; }
}

/// <summary>A row of `verification.nid_records`: the encrypted NID number and its keyed hash.</summary>
public sealed class NidRecord
{
    /// <summary>The merchant.</summary>
    public Guid ProviderId { get; set; }
    /// <summary>AES-GCM `nonce ‖ ciphertext ‖ tag`.</summary>
    public required byte[] NidCiphertext { get; set; }
    /// <summary>The keyed lookup hash.</summary>
    public required string NidHash { get; set; }
    /// <summary>When it was saved.</summary>
    public DateTimeOffset UpdatedAt { get; set; }
}

/// <summary>A row of `verification.blocked_nids`: an NID that may not enrol again (PRD §6.4).</summary>
public sealed class BlockedNidRecord
{
    /// <summary>The keyed lookup hash.</summary>
    public required string NidHash { get; set; }
    /// <summary>Why it was blocked.</summary>
    public required string Reason { get; set; }
    /// <summary>When it was blocked.</summary>
    public DateTimeOffset BlockedAt { get; set; }
}

/// <summary>A row of `verification.levels`: the merchant's level and review-queue facts.</summary>
public sealed class VerificationLevelRecord
{
    /// <summary>The merchant.</summary>
    public Guid ProviderId { get; set; }
    /// <summary>0, 1 or 2.</summary>
    public int Level { get; set; }
    /// <summary>When Level 2 was passed.</summary>
    public DateTimeOffset? Level2PassedAt { get; set; }
    /// <summary>Whether the account is suspended or banned.</summary>
    public bool Blocked { get; set; }
    /// <summary>The services offered, for the queue filter.</summary>
    public Guid[] ServiceIds { get; set; } = [];
    /// <summary>When the enrolment was sent for review.</summary>
    public DateTimeOffset? SubmittedAt { get; set; }
    /// <summary>When the row last changed.</summary>
    public DateTimeOffset UpdatedAt { get; set; }
}

/// <summary>A row of `verification.level2_sessions`: an interview, skill test or supervised job (PRD §6.3).</summary>
public sealed class Level2SessionRecord
{
    /// <summary>The id.</summary>
    public Guid Id { get; set; }
    /// <summary>The merchant.</summary>
    public Guid ProviderId { get; set; }
    /// <summary>The service tested.</summary>
    public Guid ServiceId { get; set; }
    /// <summary>When it takes place.</summary>
    public DateTimeOffset ScheduledAt { get; set; }
    /// <summary>Where it takes place.</summary>
    public required string Location { get; set; }
    /// <summary>`scheduled`, `completed` or `cancelled`.</summary>
    public required string Status { get; set; }
    /// <summary>`pass`, `fail` or `retest` once recorded.</summary>
    public string? Result { get; set; }
    /// <summary>The checklist as a JSON array of `{item, passed}`.</summary>
    public required string Checklist { get; set; }
    /// <summary>The verifier's notes.</summary>
    public required string Notes { get; set; }
    /// <summary>Where the verifier recorded the visit.</summary>
    public double? VisitLat { get; set; }
    /// <summary>Where the verifier recorded the visit.</summary>
    public double? VisitLng { get; set; }
    /// <summary>Visit photos the verifier uploaded.</summary>
    public Guid[] PhotoMediaIds { get; set; } = [];
    /// <summary>The verifier who recorded the result.</summary>
    public Guid? DecidedBy { get; set; }
    /// <summary>When the result was recorded.</summary>
    public DateTimeOffset? DecidedAt { get; set; }
    /// <summary>When it was booked.</summary>
    public DateTimeOffset CreatedAt { get; set; }
}

/// <summary>A row of `verification.reminders_sent`: one expiry reminder already sent (P-11).</summary>
public sealed class ExpiryReminderRecord
{
    /// <summary>The merchant.</summary>
    public Guid ProviderId { get; set; }
    /// <summary>The expiring item.</summary>
    public required string ItemType { get; set; }
    /// <summary>The expiry the reminder was about.</summary>
    public DateTimeOffset ExpiresAt { get; set; }
    /// <summary>How many days ahead it was sent.</summary>
    public int DaysBefore { get; set; }
    /// <summary>When it was sent.</summary>
    public DateTimeOffset SentAt { get; set; }
}

/// <summary>A row of `verification.closed_accounts`: a deleted account waiting out document retention (ADR-0023).</summary>
public sealed class ClosedAccountRecord
{
    /// <summary>The merchant.</summary>
    public Guid ProviderId { get; set; }
    /// <summary>When the account was deleted.</summary>
    public DateTimeOffset ClosedAt { get; set; }
}
