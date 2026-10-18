namespace PAO.Lib.Areas.Verification;

/// <summary>Item statuses as stored.</summary>
public static class ItemStatus
{
    /// <summary>Never submitted.</summary>
    public const string Missing = "missing";
    /// <summary>Waiting for a verifier.</summary>
    public const string Pending = "pending";
    /// <summary>Approved.</summary>
    public const string Approved = "approved";
    /// <summary>Rejected with a reason.</summary>
    public const string Rejected = "rejected";
    /// <summary>Approved once, now past its validity.</summary>
    public const string Expired = "expired";
}

/// <summary>Why a verification rule refused something; the first one is shared with the contract.</summary>
public static class VerificationReasons
{
    /// <summary>Verification has no record of the merchant or session.</summary>
    public const string NotFound = VerificationErrors.ProviderNotFound;
    /// <summary>The request breaks a rule the schema cannot express.</summary>
    public const string Invalid = "verification.invalid";
    /// <summary>The item is not waiting for a decision.</summary>
    public const string NotPending = "verification.not_pending";
    /// <summary>The police clearance is too old or dated in the future.</summary>
    public const string ClearanceTooOld = "verification.clearance_too_old";
    /// <summary>The NID is on the block list.</summary>
    public const string NidBlocked = "verification.nid_blocked";
    /// <summary>The upload is not the merchant's confirmed file of an allowed purpose.</summary>
    public const string BadDocument = "verification.bad_document";
    /// <summary>Level 2 needs a Level 1 merchant.</summary>
    public const string NotEligible = "verification.not_eligible";
    /// <summary>The merchant failed Level 2 recently.</summary>
    public const string CoolingOff = "verification.cooling_off";
    /// <summary>The session already has a result.</summary>
    public const string SessionClosed = "verification.session_closed";
    /// <summary>Required enrolment steps are still open.</summary>
    public const string EnrolmentPending = "verification.enrolment_pending";
}

/// <summary>One requirement's review state.</summary>
public sealed record ItemState
{
    /// <summary>The item type.</summary>
    public required string Type { get; init; }
    /// <summary>The status.</summary>
    public required string Status { get; init; }
    /// <summary>The rejection reason; empty otherwise.</summary>
    public string Reason { get; init; } = string.Empty;
    /// <summary>Submitted values, e.g. the clearance issue date.</summary>
    public IReadOnlyDictionary<string, string> Fields { get; init; } = new Dictionary<string, string>();
    /// <summary>When it was last submitted.</summary>
    public DateTimeOffset? SubmittedAt { get; init; }
    /// <summary>When a verifier decided it.</summary>
    public DateTimeOffset? DecidedAt { get; init; }
    /// <summary>Who decided it.</summary>
    public Guid? DecidedBy { get; init; }
    /// <summary>When the approval stops counting.</summary>
    public DateTimeOffset? ExpiresAt { get; init; }

    /// <summary>An item never submitted.</summary>
    public static ItemState Missing(string type) => new() { Type = type, Status = ItemStatus.Missing };
}

/// <summary>One line of a Level 2 checklist; stored as `{item, passed}`.</summary>
public sealed record CheckItem
{
    /// <summary>What was checked.</summary>
    public required string Item { get; init; }
    /// <summary>Whether it passed.</summary>
    public required bool Passed { get; init; }
}

/// <summary>A Level 2 interview, skill test or supervised job (PRD §6.3).</summary>
public sealed record Level2SessionState
{
    /// <summary>The id.</summary>
    public required Guid Id { get; init; }
    /// <summary>The merchant.</summary>
    public required Guid ProviderId { get; init; }
    /// <summary>The service tested.</summary>
    public required Guid ServiceId { get; init; }
    /// <summary>When it takes place.</summary>
    public required DateTimeOffset ScheduledAt { get; init; }
    /// <summary>Where it takes place.</summary>
    public required string Location { get; init; }
    /// <summary>`scheduled`, `completed` or `cancelled`.</summary>
    public required string Status { get; init; }
    /// <summary>The result; empty until recorded.</summary>
    public string Result { get; init; } = string.Empty;
    /// <summary>The checklist.</summary>
    public IReadOnlyList<CheckItem> Checklist { get; init; } = [];
    /// <summary>The verifier's notes.</summary>
    public string Notes { get; init; } = string.Empty;
    /// <summary>Where the visit was recorded.</summary>
    public double? VisitLat { get; init; }
    /// <summary>Where the visit was recorded.</summary>
    public double? VisitLng { get; init; }
    /// <summary>Visit photos.</summary>
    public IReadOnlyList<Guid> Photos { get; init; } = [];
    /// <summary>The verifier who recorded the result.</summary>
    public Guid? DecidedBy { get; init; }
    /// <summary>When the result was recorded.</summary>
    public DateTimeOffset? DecidedAt { get; init; }
    /// <summary>When it was booked.</summary>
    public required DateTimeOffset CreatedAt { get; init; }
}

/// <summary>A recorded Level 2 result.</summary>
public sealed record Level2Outcome
{
    /// <summary>`pass`, `fail` or `retest`.</summary>
    public required string Result { get; init; }
    /// <summary>The checklist.</summary>
    public required IReadOnlyList<CheckItem> Checklist { get; init; }
    /// <summary>The notes.</summary>
    public required string Notes { get; init; }
    /// <summary>Where the visit was recorded.</summary>
    public double? VisitLat { get; init; }
    /// <summary>Where the visit was recorded.</summary>
    public double? VisitLng { get; init; }
    /// <summary>Visit photos.</summary>
    public required IReadOnlyList<Guid> Photos { get; init; }
}

/// <summary>An uploaded file attached to an item, e.g. kind `nid_front`.</summary>
public sealed record VerificationDocument
{
    /// <summary>The id.</summary>
    public required Guid Id { get; init; }
    /// <summary>The item.</summary>
    public required string ItemType { get; init; }
    /// <summary>The kind.</summary>
    public required string Kind { get; init; }
    /// <summary>The media object.</summary>
    public required Guid MediaId { get; init; }
    /// <summary>When it was attached.</summary>
    public required DateTimeOffset CreatedAt { get; init; }
}

/// <summary>
/// Everything Verification knows about one merchant. A change edits it in place and the
/// repository saves it together with the change's events.
/// </summary>
public sealed class VerificationState(Guid providerId)
{
    /// <summary>The merchant.</summary>
    public Guid ProviderId { get; } = providerId;
    /// <summary>Items by type; absent ones are missing.</summary>
    public Dictionary<string, ItemState> Items { get; } = new(StringComparer.Ordinal);
    /// <summary>0, 1 or 2.</summary>
    public int Level { get; set; }
    /// <summary>When Level 2 was passed.</summary>
    public DateTimeOffset? Level2PassedAt { get; set; }
    /// <summary>Whether the account is suspended or banned.</summary>
    public bool Blocked { get; set; }
    /// <summary>The services offered.</summary>
    public IReadOnlyList<Guid> ServiceIds { get; set; } = [];
    /// <summary>When the enrolment was sent for review.</summary>
    public DateTimeOffset? SubmittedAt { get; set; }
    /// <summary>Level 2 sessions, oldest first.</summary>
    public List<Level2SessionState> Sessions { get; set; } = [];
    /// <summary>The current documents.</summary>
    public List<VerificationDocument> Documents { get; } = [];
    /// <summary>Documents replacing the current ones of their item types when saved.</summary>
    public List<VerificationDocument> NewDocuments { get; } = [];
    /// <summary>The encrypted NID number.</summary>
    public byte[]? NidCiphertext { get; set; }
    /// <summary>The NID's keyed lookup hash.</summary>
    public string? NidHash { get; set; }
    /// <summary>Marks a new NID to save.</summary>
    public bool NidChanged { get; set; }

    /// <summary>The item of `type`, missing when never submitted.</summary>
    public ItemState ItemOf(string type) => Items.TryGetValue(type, out var item) ? item : ItemState.Missing(type);
}
