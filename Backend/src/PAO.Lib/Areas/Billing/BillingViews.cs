using System.Text.Json.Serialization;

namespace PAO.Lib.Areas.Billing;

/// <summary>The spec's `PaymentSubmissionInput`: a merchant reporting a payment of the due.</summary>
public sealed record PaymentInput
{
    /// <summary>The amount in paisa.</summary>
    public long AmountPaisa { get; init; }
    /// <summary>`cash_to_agent`, `bkash`, `nagad` or `bank`.</summary>
    public string Method { get; init; } = string.Empty;
    /// <summary>The transaction id, receipt number or agent name.</summary>
    public string Reference { get; init; } = string.Empty;
}

/// <summary>The spec's `PaymentRejectInput`.</summary>
public sealed record RejectInput
{
    /// <summary>Why the payment was rejected.</summary>
    public string Reason { get; init; } = string.Empty;
}

/// <summary>The spec's `DueSummary`.</summary>
public sealed record DueSummaryView
{
    /// <summary>The due in paisa.</summary>
    public required long Due { get; init; }
    /// <summary>The block limit in paisa.</summary>
    public required long BlockAmount { get; init; }
    /// <summary>Whether accepting is refused.</summary>
    public required bool Blocked { get; init; }
    /// <summary>The commission rate in basis points.</summary>
    public required int CommissionRateBp { get; init; }
    /// <summary>Paisa reported but not reviewed yet.</summary>
    public required long PendingPayments { get; init; }
}

/// <summary>The spec's `LedgerEntry`.</summary>
public sealed record LedgerEntryView
{
    /// <summary>The id.</summary>
    public required Guid Id { get; init; }
    /// <summary>`commission` or `payment`.</summary>
    public required string Kind { get; init; }
    /// <summary>The amount in paisa.</summary>
    public required long Amount { get; init; }
    /// <summary>The booking of a commission.</summary>
    [JsonIgnore(Condition = JsonIgnoreCondition.WhenWritingNull)]
    public Guid? BookingId { get; init; }
    /// <summary>The booking number of a commission.</summary>
    [JsonIgnore(Condition = JsonIgnoreCondition.WhenWritingNull)]
    public string? BookingNumber { get; init; }
    /// <summary>The job's final price of a commission.</summary>
    [JsonIgnore(Condition = JsonIgnoreCondition.WhenWritingNull)]
    public long? JobTotal { get; init; }
    /// <summary>The submission of a payment.</summary>
    [JsonIgnore(Condition = JsonIgnoreCondition.WhenWritingNull)]
    public Guid? SubmissionId { get; init; }
    /// <summary>When it was booked.</summary>
    public required string CreatedAt { get; init; }
}

/// <summary>The spec's `LedgerEntryList`.</summary>
public sealed record LedgerEntryListView
{
    /// <summary>The rows.</summary>
    public required IReadOnlyList<LedgerEntryView> Items { get; init; }
    /// <summary>The cursor of the next page.</summary>
    [JsonIgnore(Condition = JsonIgnoreCondition.WhenWritingNull)]
    public string? NextCursor { get; init; }
}

/// <summary>The spec's `PaymentSubmission`.</summary>
public sealed record PaymentSubmissionView
{
    /// <summary>The id.</summary>
    public required Guid Id { get; init; }
    /// <summary>The merchant.</summary>
    public required Guid ProviderId { get; init; }
    /// <summary>The amount in paisa.</summary>
    public required long Amount { get; init; }
    /// <summary>The method.</summary>
    public required string Method { get; init; }
    /// <summary>The reference.</summary>
    public required string Reference { get; init; }
    /// <summary>`pending`, `confirmed` or `rejected`.</summary>
    public required string Status { get; init; }
    /// <summary>The reviewing admin.</summary>
    [JsonIgnore(Condition = JsonIgnoreCondition.WhenWritingNull)]
    public Guid? ReviewerId { get; init; }
    /// <summary>Why it was rejected.</summary>
    [JsonIgnore(Condition = JsonIgnoreCondition.WhenWritingNull)]
    public string? Reason { get; init; }
    /// <summary>When it was submitted.</summary>
    public required string CreatedAt { get; init; }
    /// <summary>When it was reviewed.</summary>
    [JsonIgnore(Condition = JsonIgnoreCondition.WhenWritingNull)]
    public string? ReviewedAt { get; init; }
}

/// <summary>The spec's `PaymentSubmissionList`.</summary>
public sealed record PaymentSubmissionListView
{
    /// <summary>The rows.</summary>
    public required IReadOnlyList<PaymentSubmissionView> Items { get; init; }
    /// <summary>The cursor of the next page.</summary>
    [JsonIgnore(Condition = JsonIgnoreCondition.WhenWritingNull)]
    public string? NextCursor { get; init; }
}

/// <summary>The spec's `MerchantLedger`.</summary>
public sealed record MerchantLedgerView
{
    /// <summary>The merchant.</summary>
    public required Guid ProviderId { get; init; }
    /// <summary>The due.</summary>
    public required DueSummaryView Summary { get; init; }
    /// <summary>The newest ledger entries.</summary>
    public required LedgerEntryListView Entries { get; init; }
}
