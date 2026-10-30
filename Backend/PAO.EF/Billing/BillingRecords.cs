using Microsoft.EntityFrameworkCore;
using Microsoft.EntityFrameworkCore.Metadata.Builders;

namespace PAO.EF.Billing;

/// <summary>A row of `billing.ledger_entries`: a commission debit or a confirmed payment credit.</summary>
public sealed class LedgerEntryRecord
{
    /// <summary>The id.</summary>
    public Guid Id { get; set; }
    /// <summary>The merchant.</summary>
    public Guid ProviderId { get; set; }
    /// <summary>`commission` or `payment`.</summary>
    public required string Kind { get; set; }
    /// <summary>The amount in paisa, never negative; the kind gives the sign.</summary>
    public long AmountPaisa { get; set; }
    /// <summary>The booking of a commission.</summary>
    public Guid? BookingId { get; set; }
    /// <summary>The booking's sequence number.</summary>
    public long? BookingNumber { get; set; }
    /// <summary>The job's final price.</summary>
    public long? JobTotalPaisa { get; set; }
    /// <summary>The rate the commission was charged at.</summary>
    public int? RateBp { get; set; }
    /// <summary>The submission of a payment.</summary>
    public Guid? SubmissionId { get; set; }
    /// <summary>When it was booked.</summary>
    public DateTimeOffset CreatedAt { get; set; }
}

/// <summary>A row of `billing.payment_submissions`: a merchant's report of a payment.</summary>
public sealed class PaymentSubmissionRecord
{
    /// <summary>The id.</summary>
    public Guid Id { get; set; }
    /// <summary>The merchant.</summary>
    public Guid ProviderId { get; set; }
    /// <summary>The amount in paisa.</summary>
    public long AmountPaisa { get; set; }
    /// <summary>`cash_to_agent`, `bkash`, `nagad` or `bank`.</summary>
    public required string Method { get; set; }
    /// <summary>The reference.</summary>
    public required string Reference { get; set; }
    /// <summary>`pending`, `confirmed` or `rejected`.</summary>
    public required string Status { get; set; }
    /// <summary>The reviewing admin.</summary>
    public Guid? ReviewerId { get; set; }
    /// <summary>Why it was rejected.</summary>
    public required string Reason { get; set; }
    /// <summary>When it was submitted.</summary>
    public DateTimeOffset CreatedAt { get; set; }
    /// <summary>When it was reviewed.</summary>
    public DateTimeOffset? ReviewedAt { get; set; }
}

/// <summary>Maps the Billing records to the `billing` schema.</summary>
public sealed class BillingConfiguration : IEntityTypeConfiguration<LedgerEntryRecord>, IEntityTypeConfiguration<PaymentSubmissionRecord>
{
    /// <inheritdoc />
    public void Configure(EntityTypeBuilder<LedgerEntryRecord> builder)
    {
        builder.ToTable("ledger_entries", Schemas.Billing);
        builder.HasKey(e => e.Id);
    }

    /// <inheritdoc />
    public void Configure(EntityTypeBuilder<PaymentSubmissionRecord> builder)
    {
        builder.ToTable("payment_submissions", Schemas.Billing);
        builder.HasKey(s => s.Id);
    }
}
