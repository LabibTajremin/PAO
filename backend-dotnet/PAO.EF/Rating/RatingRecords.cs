using Microsoft.EntityFrameworkCore;
using Microsoft.EntityFrameworkCore.Metadata.Builders;

namespace PAO.EF.Rating;

/// <summary>A row of `rating.reviewable_bookings`: a completed booking both sides may review.</summary>
public sealed class ReviewableBookingRecord
{
    /// <summary>The booking.</summary>
    public Guid BookingId { get; set; }
    /// <summary>The customer.</summary>
    public Guid CustomerId { get; set; }
    /// <summary>The provider.</summary>
    public Guid ProviderId { get; set; }
    /// <summary>The customer's name.</summary>
    public required string CustomerName { get; set; }
    /// <summary>The provider's name.</summary>
    public required string ProviderName { get; set; }
    /// <summary>The service name in English.</summary>
    public required string ServiceNameEn { get; set; }
    /// <summary>The service name in Bangla.</summary>
    public required string ServiceNameBn { get; set; }
    /// <summary>When the job was completed.</summary>
    public DateTimeOffset CompletedAt { get; set; }
}

/// <summary>A row of `rating.reviews`: one side's review of the other.</summary>
public sealed class ReviewRecord
{
    /// <summary>The id.</summary>
    public Guid Id { get; set; }
    /// <summary>The booking.</summary>
    public Guid BookingId { get; set; }
    /// <summary>The author.</summary>
    public Guid AuthorId { get; set; }
    /// <summary>`customer` or `provider`.</summary>
    public required string AuthorRole { get; set; }
    /// <summary>The author's first name.</summary>
    public required string AuthorName { get; set; }
    /// <summary>Who is reviewed.</summary>
    public Guid SubjectId { get; set; }
    /// <summary>1 to 5.</summary>
    public int Stars { get; set; }
    /// <summary>The tags.</summary>
    public required string[] Tags { get; set; }
    /// <summary>The comment.</summary>
    public required string Comment { get; set; }
    /// <summary>The service name in English.</summary>
    public required string ServiceNameEn { get; set; }
    /// <summary>The service name in Bangla.</summary>
    public required string ServiceNameBn { get; set; }
    /// <summary>When it was written.</summary>
    public DateTimeOffset CreatedAt { get; set; }
}

/// <summary>A row of `rating.aggregates`: a subject's running totals.</summary>
public sealed class RatingAggregateRecord
{
    /// <summary>Who is rated.</summary>
    public Guid SubjectId { get; set; }
    /// <summary>`customer` or `provider`.</summary>
    public required string SubjectRole { get; set; }
    /// <summary>How many reviews.</summary>
    public int ReviewCount { get; set; }
    /// <summary>The sum of their stars.</summary>
    public long StarSum { get; set; }
    /// <summary>One-star reviews.</summary>
    public int Stars1 { get; set; }
    /// <summary>Two-star reviews.</summary>
    public int Stars2 { get; set; }
    /// <summary>Three-star reviews.</summary>
    public int Stars3 { get; set; }
    /// <summary>Four-star reviews.</summary>
    public int Stars4 { get; set; }
    /// <summary>Five-star reviews.</summary>
    public int Stars5 { get; set; }
}

/// <summary>Maps the Rating records to the `rating` schema.</summary>
public sealed class RatingConfiguration :
    IEntityTypeConfiguration<ReviewableBookingRecord>, IEntityTypeConfiguration<ReviewRecord>, IEntityTypeConfiguration<RatingAggregateRecord>
{
    /// <inheritdoc />
    public void Configure(EntityTypeBuilder<ReviewableBookingRecord> builder)
    {
        builder.ToTable("reviewable_bookings", Schemas.Rating);
        builder.HasKey(r => r.BookingId);
    }

    /// <inheritdoc />
    public void Configure(EntityTypeBuilder<ReviewRecord> builder)
    {
        builder.ToTable("reviews", Schemas.Rating);
        builder.HasKey(r => r.Id);
    }

    /// <inheritdoc />
    public void Configure(EntityTypeBuilder<RatingAggregateRecord> builder)
    {
        builder.ToTable("aggregates", Schemas.Rating);
        builder.HasKey(a => new { a.SubjectId, a.SubjectRole });
        builder.Property(a => a.Stars1).HasColumnName("stars_1");
        builder.Property(a => a.Stars2).HasColumnName("stars_2");
        builder.Property(a => a.Stars3).HasColumnName("stars_3");
        builder.Property(a => a.Stars4).HasColumnName("stars_4");
        builder.Property(a => a.Stars5).HasColumnName("stars_5");
    }
}
