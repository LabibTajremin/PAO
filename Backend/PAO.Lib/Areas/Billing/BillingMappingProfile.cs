using PAO.EF.Billing;
using PAO.Lib.Areas.Booking;
using PAO.Lib.Common;
using PAO.Lib.Mapping;

namespace PAO.Lib.Areas.Billing;

/// <summary>A merchant's totals: commission debits, confirmed credits and unreviewed payments.</summary>
public sealed record DueTotals(long DebitPaisa, long CreditPaisa, long PendingPaisa)
{
    /// <summary>
    /// The due (ADR-0035 §3): every commission debit minus every confirmed payment credit,
    /// never below zero, so an overpayment does not show as a negative due. Payments still
    /// pending review do not count.
    /// </summary>
    public long DuePaisa => Math.Max(0, DebitPaisa - CreditPaisa);
}

/// <summary>A merchant's totals with the settings they are judged by.</summary>
public sealed record DueWithLimits(DueTotals Totals, int RateBp, long BlockPaisa)
{
    /// <summary>Accepting is refused while the due is above the block limit.</summary>
    public bool Blocked => Totals.DuePaisa > BlockPaisa;
}

/// <summary>The Billing area's maps.</summary>
public sealed class BillingMappingProfile : IMappingProfile
{
    /// <inheritdoc />
    public void Configure(MappingRegistry registry) => registry
        .Add<DueWithLimits, DueSummaryView>((d, _) => new DueSummaryView
        {
            Due = d.Totals.DuePaisa,
            BlockAmount = d.BlockPaisa,
            Blocked = d.Blocked,
            CommissionRateBp = d.RateBp,
            PendingPayments = d.Totals.PendingPaisa,
        })
        .Add<DueWithLimits, DueStatus>((d, _) => new DueStatus { DuePaisa = d.Totals.DuePaisa, BlockAmountPaisa = d.BlockPaisa, Blocked = d.Blocked })
        .Add<LedgerEntryRecord, LedgerEntryView>((e, _) => new LedgerEntryView
        {
            Id = e.Id,
            Kind = e.Kind,
            Amount = e.AmountPaisa,
            BookingId = e.BookingId,
            BookingNumber = e.BookingNumber is { } n ? BookingNumbers.Format(n) : null,
            JobTotal = e.JobTotalPaisa,
            SubmissionId = e.SubmissionId,
            CreatedAt = IsoTime.Format(e.CreatedAt),
        })
        .Add<PaymentSubmissionRecord, PaymentSubmissionView>((s, _) => new PaymentSubmissionView
        {
            Id = s.Id,
            ProviderId = s.ProviderId,
            Amount = s.AmountPaisa,
            Method = s.Method,
            Reference = s.Reference,
            Status = s.Status,
            ReviewerId = s.ReviewerId,
            Reason = s.Reason.Length == 0 ? null : s.Reason,
            CreatedAt = IsoTime.Format(s.CreatedAt),
            ReviewedAt = s.ReviewedAt is { } at ? IsoTime.Format(at) : null,
        });
}
