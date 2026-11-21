using PAO.Lib.Areas.Billing;

namespace PAO.Core.Areas.Billing.Services.Shared;

/// <summary>
/// What other areas may ask of the Billing area; the only way they reach it (PRD §9.3
/// rule 1, enforced by the architecture tests).
/// </summary>
public interface IBillingSharedService
{
    /// <summary>Returns the merchant's due against the block limit; Booking checks it before an accept (ADR-0035 §3).</summary>
    Task<DueStatus> GetDueStatus(Guid merchantId, CancellationToken cancellationToken);

    /// <summary>Debits PAO's commission on a completed job to the merchant's ledger (ADR-0035 §2); idempotent per booking.</summary>
    Task RecordCommission(CommissionRequest request, CancellationToken cancellationToken);
}
