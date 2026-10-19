using PAO.Lib.Events;

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
    /// <summary>The booking's sequence number, e.g. 104233.</summary>
    public long BookingNumber { get; init; }
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
    /// <summary>The `"billing.not_found"` value: no such payment submission.</summary>
    public const string NotFound = "billing.not_found";
    /// <summary>The `"billing.not_pending"` value: the submission was already reviewed.</summary>
    public const string NotPending = "billing.not_pending";
}

/// <summary>The values of the Billing area's enumerations.</summary>
public static class BillingKinds
{
    /// <summary>A ledger debit for a completed job.</summary>
    public const string Commission = "commission";
    /// <summary>A ledger credit for a confirmed payment.</summary>
    public const string Payment = "payment";
    /// <summary>A submission waiting for review.</summary>
    public const string Pending = "pending";
    /// <summary>A confirmed submission.</summary>
    public const string Confirmed = "confirmed";
    /// <summary>A rejected submission.</summary>
    public const string Rejected = "rejected";
}

/// <summary>Names of the events the Billing area publishes.</summary>
public static class BillingEvents
{
    /// <summary>The `"billing.CommissionCharged"` value.</summary>
    public const string CommissionCharged = "billing.CommissionCharged";
    /// <summary>The `"billing.PaymentSubmitted"` value.</summary>
    public const string PaymentSubmitted = "billing.PaymentSubmitted";
    /// <summary>The `"billing.PaymentConfirmed"` value.</summary>
    public const string PaymentConfirmed = "billing.PaymentConfirmed";
    /// <summary>The `"billing.PaymentRejected"` value.</summary>
    public const string PaymentRejected = "billing.PaymentRejected";
}

/// <summary>PAO's commission on a completed job was debited to the merchant.</summary>
public sealed record CommissionCharged : IDomainEvent
{
    /// <summary>The name.</summary>
    public string Name { get; } = BillingEvents.CommissionCharged;
    /// <summary>The merchant.</summary>
    public required Guid ProviderId { get; init; }
    /// <summary>The booking.</summary>
    public required Guid BookingId { get; init; }
    /// <summary>The commission in paisa.</summary>
    public required long AmountPaisa { get; init; }
    /// <summary>The due after the debit.</summary>
    public required long DuePaisa { get; init; }
    /// <summary>Whether the due is now above the block limit.</summary>
    public required bool Blocked { get; init; }
}

/// <summary>The fields every payment submission event carries.</summary>
public abstract record PaymentEvent(string Name) : IDomainEvent
{
    /// <summary>The submission.</summary>
    public Guid SubmissionId { get; init; }
    /// <summary>The merchant.</summary>
    public Guid ProviderId { get; init; }
    /// <summary>The amount in paisa.</summary>
    public long AmountPaisa { get; init; }
    /// <summary>The method.</summary>
    public string Method { get; init; } = string.Empty;
    /// <summary>The due after the change.</summary>
    public long DuePaisa { get; init; }
    /// <summary>Why it was rejected; empty otherwise.</summary>
    public string Reason { get; init; } = string.Empty;
    /// <summary>Who acted: the merchant on submit, the admin on review.</summary>
    public Guid? ActorId { get; init; }
}

/// <summary>A merchant reported a payment.</summary>
public sealed record PaymentSubmitted() : PaymentEvent(BillingEvents.PaymentSubmitted);

/// <summary>An admin confirmed a payment; the ledger was credited.</summary>
public sealed record PaymentConfirmed() : PaymentEvent(BillingEvents.PaymentConfirmed);

/// <summary>An admin rejected a payment with a reason.</summary>
public sealed record PaymentRejected() : PaymentEvent(BillingEvents.PaymentRejected);
