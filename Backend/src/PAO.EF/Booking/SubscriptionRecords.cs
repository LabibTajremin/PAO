using Microsoft.EntityFrameworkCore;
using Microsoft.EntityFrameworkCore.Metadata.Builders;

namespace PAO.EF.Booking;

/// <summary>A row of `booking.subscriptions`: a scheduled-delivery order and its snapshots (ADR-0041).</summary>
public sealed class SubscriptionRecord
{
    /// <summary>The id.</summary>
    public Guid Id { get; set; }
    /// <summary>The sequence number shown as `PAO-S-{number}`.</summary>
    public long Number { get; set; }
    /// <summary>The customer.</summary>
    public Guid CustomerId { get; set; }
    /// <summary>The merchant.</summary>
    public Guid ProviderId { get; set; }
    /// <summary>The service.</summary>
    public Guid ServiceId { get; set; }
    /// <summary>The service name in English.</summary>
    public required string ServiceNameEn { get; set; }
    /// <summary>The service name in Bangla.</summary>
    public required string ServiceNameBn { get; set; }
    /// <summary>The customer's name snapshot.</summary>
    public required string CustomerName { get; set; }
    /// <summary>The customer's phone snapshot.</summary>
    public required string CustomerPhone { get; set; }
    /// <summary>The merchant's name snapshot.</summary>
    public required string ProviderName { get; set; }
    /// <summary>The merchant's phone snapshot.</summary>
    public required string ProviderPhone { get; set; }
    /// <summary>The saved address it was copied from.</summary>
    public Guid AddressId { get; set; }
    /// <summary>The area.</summary>
    public required string AddressArea { get; set; }
    /// <summary>The first line.</summary>
    public required string AddressLine1 { get; set; }
    /// <summary>The second line.</summary>
    public required string AddressLine2 { get; set; }
    /// <summary>The latitude.</summary>
    public double AddressLat { get; set; }
    /// <summary>The longitude.</summary>
    public double AddressLng { get; set; }
    /// <summary>The note.</summary>
    public required string Note { get; set; }
    /// <summary>The priced lines of one delivery as JSON.</summary>
    public required string Items { get; set; }
    /// <summary>The total of one delivery.</summary>
    public long TotalPaisa { get; set; }
    /// <summary>What the quantity counts.</summary>
    public required string Unit { get; set; }
    /// <summary>The repeat pattern.</summary>
    public required string Pattern { get; set; }
    /// <summary>The days of the week.</summary>
    public int[] Weekdays { get; set; } = [];
    /// <summary>The day of the month.</summary>
    public int? DayOfMonth { get; set; }
    /// <summary>The window start.</summary>
    public TimeOnly WindowStart { get; set; }
    /// <summary>The window end.</summary>
    public TimeOnly WindowEnd { get; set; }
    /// <summary>The cutoff on the day before.</summary>
    public TimeOnly Cutoff { get; set; }
    /// <summary>The first date.</summary>
    public DateOnly StartDate { get; set; }
    /// <summary>The last date.</summary>
    public DateOnly? EndDate { get; set; }
    /// <summary>The count.</summary>
    public int? Count { get; set; }
    /// <summary>The status.</summary>
    public required string Status { get; set; }
    /// <summary>The merchant's reason for declining.</summary>
    public required string DeclineReason { get; set; }
    /// <summary>The idempotency key.</summary>
    public required string IdempotencyKey { get; set; }
    /// <summary>When it was ordered.</summary>
    public DateTimeOffset CreatedAt { get; set; }
    /// <summary>When it last changed.</summary>
    public DateTimeOffset UpdatedAt { get; set; }
    /// <summary>When the merchant accepted.</summary>
    public DateTimeOffset? AcceptedAt { get; set; }
}

/// <summary>A row of `booking.subscription_dates`: one date that differs from the plan or became a booking.</summary>
public sealed class SubscriptionDateRecord
{
    /// <summary>The subscription.</summary>
    public Guid SubscriptionId { get; set; }
    /// <summary>The date.</summary>
    public DateOnly Date { get; set; }
    /// <summary>skipped, changed, declined, cancelled or booked.</summary>
    public required string State { get; set; }
    /// <summary>The date's own priced lines as JSON, when changed.</summary>
    public string? Items { get; set; }
    /// <summary>The booking it became.</summary>
    public Guid? BookingId { get; set; }
    /// <summary>When it last changed.</summary>
    public DateTimeOffset UpdatedAt { get; set; }
}

/// <summary>Maps the subscription tables.</summary>
public sealed class SubscriptionConfigurations : IEntityTypeConfiguration<SubscriptionRecord>, IEntityTypeConfiguration<SubscriptionDateRecord>
{
    /// <inheritdoc />
    public void Configure(EntityTypeBuilder<SubscriptionRecord> builder)
    {
        builder.ToTable("subscriptions", Schemas.Booking);
        builder.HasKey(s => s.Id);
        builder.Property(s => s.Number).ValueGeneratedOnAdd();
        builder.Property(s => s.Items).HasColumnType("jsonb");
    }

    /// <inheritdoc />
    public void Configure(EntityTypeBuilder<SubscriptionDateRecord> builder)
    {
        builder.ToTable("subscription_dates", Schemas.Booking);
        builder.HasKey(d => new { d.SubscriptionId, d.Date });
        builder.Property(d => d.Items).HasColumnType("jsonb");
    }
}
