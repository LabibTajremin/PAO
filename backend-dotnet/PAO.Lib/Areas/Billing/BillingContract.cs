namespace PAO.Lib.Areas.Billing;

/// <summary>
/// A merchant's due against the block limit (ADR-0035 §3): accepting is refused while
/// `DuePaisa` is above `BlockAmountPaisa`.
/// </summary>
public sealed record DueStatus
{
    /// <summary>The due paisa.</summary>
    public required long DuePaisa { get; init; }
    /// <summary>The block amount paisa.</summary>
    public required long BlockAmountPaisa { get; init; }
    /// <summary>Whether blocked.</summary>
    public required bool Blocked { get; init; }
}

/// <summary>Records PAO's commission on a completed job (ADR-0035 §2).</summary>
public sealed record CommissionRequest
{
    /// <summary>The booking id.</summary>
    public required Guid BookingId { get; init; }
    /// <summary>The merchant id.</summary>
    public required Guid MerchantId { get; init; }
    /// <summary>The final price paisa.</summary>
    public required long FinalPricePaisa { get; init; }
}

/// <summary>The Billing area's error reasons.</summary>
public static class BillingErrors
{
    /// <summary>The `"billing.due_limit"` value.</summary>
    public const string DueLimit = "billing.due_limit";
}
