using Microsoft.EntityFrameworkCore;
using Microsoft.EntityFrameworkCore.Metadata.Builders;
using NetTopologySuite.Geometries;

namespace PAO.EF.Merchant;

/// <summary>
/// A row of `provider.providers`: the enrolment profile plus the copies other areas' events
/// keep current (account status, level, rating, jobs, review flag).
/// </summary>
public sealed class MerchantProfileRecord
{
    /// <summary>The account id.</summary>
    public Guid Id { get; set; }
    /// <summary>The account phone.</summary>
    public required string Phone { get; set; }
    /// <summary>The name as on the NID.</summary>
    public required string FullName { get; set; }
    /// <summary>The Dhaka calendar date of birth.</summary>
    public DateOnly? DateOfBirth { get; set; }
    /// <summary>`female`, `male`, `other` or null before the personal step.</summary>
    public string? Gender { get; set; }
    /// <summary>The present address.</summary>
    public required string PresentAddress { get; set; }
    /// <summary>The permanent address.</summary>
    public required string PermanentAddress { get; set; }
    /// <summary>The bio.</summary>
    public required string Bio { get; set; }
    /// <summary>The confirmed avatar upload, if any.</summary>
    public Guid? PhotoMediaId { get; set; }
    /// <summary>Years of experience.</summary>
    public int ExperienceYears { get; set; }
    /// <summary>`en` or `bn`.</summary>
    public required string Language { get; set; }
    /// <summary>Where the merchant works from; X is the longitude.</summary>
    public Point? HomeBase { get; set; }
    /// <summary>How far from the home base they travel, in metres.</summary>
    public int WorkingRadiusM { get; set; }
    /// <summary>The guarantor's name.</summary>
    public required string EmergencyName { get; set; }
    /// <summary>The guarantor's relation.</summary>
    public required string EmergencyRelation { get; set; }
    /// <summary>The guarantor's phone.</summary>
    public required string EmergencyPhone { get; set; }
    /// <summary>When the guarantor's code was checked.</summary>
    public DateTimeOffset? EmergencyVerifiedAt { get; set; }
    /// <summary>The accepted code-of-conduct version.</summary>
    public required string CocVersion { get; set; }
    /// <summary>When it was accepted.</summary>
    public DateTimeOffset? CocAcceptedAt { get; set; }
    /// <summary>The wizard steps done.</summary>
    public required string[] StepsDone { get; set; }
    /// <summary>When the enrolment went to review.</summary>
    public DateTimeOffset? SubmittedAt { get; set; }
    /// <summary>The account status copy.</summary>
    public required string AccountStatus { get; set; }
    /// <summary>The verification level copy.</summary>
    public int Level { get; set; }
    /// <summary>Unused; kept so the row maps whole.</summary>
    public bool CanReceiveBookings { get; set; }
    /// <summary>The rating average copy.</summary>
    public double RatingAvg { get; set; }
    /// <summary>The rating count copy.</summary>
    public int RatingCount { get; set; }
    /// <summary>Completed jobs.</summary>
    public int CompletedJobs { get; set; }
    /// <summary>Whether a quality threshold flagged them.</summary>
    public bool FlaggedForReview { get; set; }
    /// <summary>Why they were flagged.</summary>
    public required string FlagReason { get; set; }
    /// <summary>When the profile was created.</summary>
    public DateTimeOffset CreatedAt { get; set; }
    /// <summary>When it last changed.</summary>
    public DateTimeOffset UpdatedAt { get; set; }
}

/// <summary>A row of `provider.provider_services`: a service the merchant offers.</summary>
public sealed class MerchantServiceRecord
{
    /// <summary>The merchant.</summary>
    public Guid ProviderId { get; set; }
    /// <summary>The catalog service.</summary>
    public Guid ServiceId { get; set; }
}

/// <summary>A row of `provider.cancellations`: a cancellation by the merchant after acceptance (D13).</summary>
public sealed class CancellationRecord
{
    /// <summary>The booking.</summary>
    public Guid BookingId { get; set; }
    /// <summary>The merchant.</summary>
    public Guid ProviderId { get; set; }
    /// <summary>When it happened.</summary>
    public DateTimeOffset At { get; set; }
}

/// <summary>Maps the Merchant records to the `provider` schema.</summary>
public sealed class MerchantConfiguration :
    IEntityTypeConfiguration<MerchantProfileRecord>, IEntityTypeConfiguration<MerchantServiceRecord>, IEntityTypeConfiguration<CancellationRecord>
{
    /// <inheritdoc />
    public void Configure(EntityTypeBuilder<MerchantProfileRecord> builder)
    {
        builder.ToTable("providers", Schemas.Merchant);
        builder.HasKey(m => m.Id);
        builder.Property(m => m.HomeBase).HasColumnType("geography (point, 4326)");
    }

    /// <inheritdoc />
    public void Configure(EntityTypeBuilder<MerchantServiceRecord> builder)
    {
        builder.ToTable("provider_services", Schemas.Merchant);
        builder.HasKey(s => new { s.ProviderId, s.ServiceId });
    }

    /// <inheritdoc />
    public void Configure(EntityTypeBuilder<CancellationRecord> builder)
    {
        builder.ToTable("cancellations", Schemas.Merchant);
        builder.HasKey(c => c.BookingId);
    }
}
