using PAO.Lib.Common;

namespace PAO.Lib.Areas.Verification;

/// <summary>The body of saveNid (M08).</summary>
public sealed record NidInput
{
    /// <summary>The 10, 13 or 17 digit NID number.</summary>
    public required string NidNumber { get; init; }
    /// <summary>The front of the card.</summary>
    public required Guid FrontMediaId { get; init; }
    /// <summary>The back of the card.</summary>
    public required Guid BackMediaId { get; init; }
}

/// <summary>The body of saveSelfie (M09).</summary>
public sealed record SelfieInput
{
    /// <summary>The live selfie.</summary>
    public required Guid MediaId { get; init; }
}

/// <summary>The body of savePoliceClearance (M10).</summary>
public sealed record PoliceClearanceInput
{
    /// <summary>The certificate.</summary>
    public required Guid MediaId { get; init; }
    /// <summary>The issue date, a Dhaka calendar date (`YYYY-MM-DD`).</summary>
    public required DateOnly IssueDate { get; init; }
}

/// <summary>The body of saveSkillProof (M11).</summary>
public sealed record SkillProofInput
{
    /// <summary>Certificates or work photos, at most ten.</summary>
    public required IReadOnlyList<Guid> MediaIds { get; init; }
}

/// <summary>The body of rejectVerificationItem (`StatusReason`).</summary>
public sealed record RejectionInput
{
    /// <summary>Why the item is rejected; the merchant sees it.</summary>
    public required string Reason { get; init; }
}

/// <summary>The body of scheduleLevel2Session.</summary>
public sealed record Level2SessionInput
{
    /// <summary>The merchant.</summary>
    public required Guid ProviderId { get; init; }
    /// <summary>The service tested.</summary>
    public required Guid ServiceId { get; init; }
    /// <summary>When it takes place.</summary>
    public required DateTimeOffset ScheduledAt { get; init; }
    /// <summary>Where it takes place.</summary>
    public required string Location { get; init; }
}

/// <summary>The body of recordLevel2Result.</summary>
public sealed record Level2ResultInput
{
    /// <summary>`pass`, `fail` or `retest`.</summary>
    public required string Result { get; init; }
    /// <summary>The checklist.</summary>
    public required IReadOnlyList<CheckItem> Checklist { get; init; }
    /// <summary>The notes.</summary>
    public string? Notes { get; init; }
    /// <summary>Where the visit took place.</summary>
    public GeoPoint? VisitLocation { get; init; }
    /// <summary>Visit photos the verifier uploaded.</summary>
    public IReadOnlyList<Guid>? PhotoMediaIds { get; init; }
}
