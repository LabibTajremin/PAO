namespace PAO.Lib.Areas.Billing;

/// <summary>
/// A merchant's due against the block limit (ADR-0035 §3): accepting is refused while
/// `DuePaisa` is above `BlockAmountPaisa`.
/// </summary>
public sealed record DueStatus
{
    public required long DuePaisa { get; init; }
    public required long BlockAmountPaisa { get; init; }
    public required bool Blocked { get; init; }
}

/// <summary>Records PAO's commission on a completed job (ADR-0035 §2).</summary>
public sealed record CommissionRequest
{
    public required Guid BookingId { get; init; }
    public required Guid MerchantId { get; init; }
    public required long FinalPricePaisa { get; init; }
}

/// <summary>The Billing area's error reasons.</summary>
public static class BillingErrors
{
    public const string DueLimit = "billing.due_limit";
}
