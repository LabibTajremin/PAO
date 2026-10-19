using Microsoft.EntityFrameworkCore;
using Microsoft.EntityFrameworkCore.Metadata.Builders;
using NetTopologySuite.Geometries;

namespace PAO.EF.Booking;

/// <summary>
/// A row of `booking.bookings`: the request with every snapshot copied in at creation
/// (PRD §9.3 rule 4) and the columns the state machine moves.
/// </summary>
public sealed class BookingRecord
{
    /// <summary>The id.</summary>
    public Guid Id { get; set; }
    /// <summary>The sequence number shown as `PAO-{number}`.</summary>
    public long Number { get; set; }
    /// <summary>The customer.</summary>
    public Guid CustomerId { get; set; }
    /// <summary>The provider.</summary>
    public Guid ProviderId { get; set; }
    /// <summary>The catalog service.</summary>
    public Guid ServiceId { get; set; }
    /// <summary>The service name in English.</summary>
    public required string ServiceNameEn { get; set; }
    /// <summary>The service name in Bangla.</summary>
    public required string ServiceNameBn { get; set; }
    /// <summary>`on_demand` or `duration_hire`.</summary>
    public required string ServiceModel { get; set; }
    /// <summary>The customer's name snapshot.</summary>
    public required string CustomerName { get; set; }
    /// <summary>The customer's phone snapshot.</summary>
    public required string CustomerPhone { get; set; }
    /// <summary>The provider's name snapshot.</summary>
    public required string ProviderName { get; set; }
    /// <summary>The provider's phone snapshot.</summary>
    public required string ProviderPhone { get; set; }
    /// <summary>The saved address it was copied from.</summary>
    public Guid AddressId { get; set; }
    /// <summary>The area.</summary>
    public required string AddressArea { get; set; }
    /// <summary>The first address line.</summary>
    public required string AddressLine1 { get; set; }
    /// <summary>The second address line.</summary>
    public required string AddressLine2 { get; set; }
    /// <summary>The service point; X is the longitude.</summary>
    public required Point AddressLocation { get; set; }
    /// <summary>The customer's note.</summary>
    public required string Note { get; set; }
    /// <summary>The state (docs/booking-states.md).</summary>
    public required string Status { get; set; }
    /// <summary>`asap` or `scheduled`.</summary>
    public required string Timing { get; set; }
    /// <summary>When a scheduled job starts.</summary>
    public DateTimeOffset? ScheduledAt { get; set; }
    /// <summary>When a duration hire ends.</summary>
    public DateTimeOffset? EndsAt { get; set; }
    /// <summary>When the provider's time to answer runs out.</summary>
    public DateTimeOffset AcceptDeadline { get; set; }
    /// <summary>The bill.</summary>
    public long TotalPaisa { get; set; }
    /// <summary>The 4-digit code the customer reads out.</summary>
    public required string StartCode { get; set; }
    /// <summary>Wrong codes since the last lockout.</summary>
    public int StartCodeAttempts { get; set; }
    /// <summary>Until when code entry is locked.</summary>
    public DateTimeOffset? StartCodeLockedUntil { get; set; }
    /// <summary>Whether the provider confirmed the cash.</summary>
    public bool CashReceived { get; set; }
    /// <summary>The creating request's Idempotency-Key.</summary>
    public required string IdempotencyKey { get; set; }
    /// <summary>Why it was cancelled.</summary>
    public required string CancelReason { get; set; }
    /// <summary>Who cancelled; null until then.</summary>
    public string? CancelledBy { get; set; }
    /// <summary>Why the provider rejected.</summary>
    public required string RejectReason { get; set; }
    /// <summary>When it was requested.</summary>
    public DateTimeOffset CreatedAt { get; set; }
    /// <summary>When it last changed.</summary>
    public DateTimeOffset UpdatedAt { get; set; }
    /// <summary>When the provider accepted.</summary>
    public DateTimeOffset? AcceptedAt { get; set; }
    /// <summary>When the start code was entered.</summary>
    public DateTimeOffset? StartedAt { get; set; }
    /// <summary>When the job was completed.</summary>
    public DateTimeOffset? CompletedAt { get; set; }
    /// <summary>When it was cancelled.</summary>
    public DateTimeOffset? CancelledAt { get; set; }
}

/// <summary>A row of `booking.booking_items`: a priced line; lines never change once written.</summary>
public sealed class BookingItemRecord
{
    /// <summary>The id.</summary>
    public Guid Id { get; set; }
    /// <summary>The booking.</summary>
    public Guid BookingId { get; set; }
    /// <summary>The extras proposal it came with, if any.</summary>
    public Guid? ProposalId { get; set; }
    /// <summary>The catalog sub-service.</summary>
    public Guid SubServiceId { get; set; }
    /// <summary>The price version copied.</summary>
    public Guid PriceVersionId { get; set; }
    /// <summary>The English name.</summary>
    public required string NameEn { get; set; }
    /// <summary>The Bangla name.</summary>
    public required string NameBn { get; set; }
    /// <summary>The price unit.</summary>
    public required string Unit { get; set; }
    /// <summary>The quantity.</summary>
    public int Quantity { get; set; }
    /// <summary>The unit price.</summary>
    public long UnitPricePaisa { get; set; }
    /// <summary>The line total.</summary>
    public long TotalPaisa { get; set; }
    /// <summary>Whether it was added during the job.</summary>
    public bool Extra { get; set; }
    /// <summary>The order on the bill.</summary>
    public int Position { get; set; }
}

/// <summary>A row of `booking.extras_proposals`.</summary>
public sealed class ExtrasProposalRecord
{
    /// <summary>The id.</summary>
    public Guid Id { get; set; }
    /// <summary>The booking.</summary>
    public Guid BookingId { get; set; }
    /// <summary>`pending`, `approved` or `declined`.</summary>
    public required string Status { get; set; }
    /// <summary>What the items add to the bill.</summary>
    public long AddedPaisa { get; set; }
    /// <summary>When the provider proposed them.</summary>
    public DateTimeOffset ProposedAt { get; set; }
    /// <summary>When the customer answered.</summary>
    public DateTimeOffset? DecidedAt { get; set; }
}

/// <summary>A row of `booking.timeline`.</summary>
public sealed class TimelineRecord
{
    /// <summary>The id.</summary>
    public Guid Id { get; set; }
    /// <summary>The booking.</summary>
    public Guid BookingId { get; set; }
    /// <summary>The state entered.</summary>
    public required string Status { get; set; }
    /// <summary>Who moved it.</summary>
    public required string Actor { get; set; }
    /// <summary>Why, when a reason was given.</summary>
    public required string Reason { get; set; }
    /// <summary>When.</summary>
    public DateTimeOffset At { get; set; }
}

/// <summary>Maps the Booking records to the `booking` schema.</summary>
public sealed class BookingConfiguration :
    IEntityTypeConfiguration<BookingRecord>, IEntityTypeConfiguration<BookingItemRecord>,
    IEntityTypeConfiguration<ExtrasProposalRecord>, IEntityTypeConfiguration<TimelineRecord>
{
    /// <inheritdoc />
    public void Configure(EntityTypeBuilder<BookingRecord> builder)
    {
        builder.ToTable("bookings", Schemas.Booking);
        builder.HasKey(b => b.Id);
        builder.Property(b => b.Number).ValueGeneratedOnAdd();
        builder.Property(b => b.AddressLocation).HasColumnType("geography (point, 4326)");
    }

    /// <inheritdoc />
    public void Configure(EntityTypeBuilder<BookingItemRecord> builder)
    {
        builder.ToTable("booking_items", Schemas.Booking);
        builder.HasKey(i => i.Id);
        // The keys let one SaveChanges insert a booking, its proposals and items in a valid order.
        builder.HasOne<BookingRecord>().WithMany().HasForeignKey(i => i.BookingId);
        builder.HasOne<ExtrasProposalRecord>().WithMany().HasForeignKey(i => i.ProposalId);
    }

    /// <inheritdoc />
    public void Configure(EntityTypeBuilder<ExtrasProposalRecord> builder)
    {
        builder.ToTable("extras_proposals", Schemas.Booking);
        builder.HasKey(p => p.Id);
        builder.HasOne<BookingRecord>().WithMany().HasForeignKey(p => p.BookingId);
    }

    /// <inheritdoc />
    public void Configure(EntityTypeBuilder<TimelineRecord> builder)
    {
        builder.ToTable("timeline", Schemas.Booking);
        builder.HasKey(t => t.Id);
        builder.HasOne<BookingRecord>().WithMany().HasForeignKey(t => t.BookingId);
    }
}
