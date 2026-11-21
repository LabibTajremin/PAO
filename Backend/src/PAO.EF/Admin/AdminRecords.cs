using Microsoft.EntityFrameworkCore;
using Microsoft.EntityFrameworkCore.Metadata.Builders;

namespace PAO.EF.Admin;

/// <summary>A row of `admin.settings`: one admin-editable rule stored as text (A-10).</summary>
public sealed class SettingRecord
{
    /// <summary>The key, e.g. `booking.accept_timeout_asap_seconds`.</summary>
    public required string Key { get; set; }
    /// <summary>The value as text.</summary>
    public required string Value { get; set; }
    /// <summary>How to read the value.</summary>
    public required string Type { get; set; }
    /// <summary>What the setting does.</summary>
    public required string Description { get; set; }
    /// <summary>When it last changed.</summary>
    public DateTimeOffset UpdatedAt { get; set; }
    /// <summary>Who changed it last.</summary>
    public Guid? UpdatedBy { get; set; }
}

/// <summary>A row of `admin.complaints`: a problem reported on a booking (C-14, A-07).</summary>
public sealed class ComplaintRecord
{
    /// <summary>The id.</summary>
    public Guid Id { get; set; }
    /// <summary>The ticket sequence number.</summary>
    public long TicketNumber { get; set; }
    /// <summary>The booking.</summary>
    public Guid BookingId { get; set; }
    /// <summary>Who reported.</summary>
    public Guid ReporterId { get; set; }
    /// <summary>`customer` or `provider`.</summary>
    public required string ReporterRole { get; set; }
    /// <summary>The other party.</summary>
    public Guid AgainstId { get; set; }
    /// <summary>The reason.</summary>
    public required string Reason { get; set; }
    /// <summary>The description.</summary>
    public required string Description { get; set; }
    /// <summary>Evidence photos.</summary>
    public required Guid[] PhotoMediaIds { get; set; }
    /// <summary>`open`, `assigned` or `resolved`.</summary>
    public required string Status { get; set; }
    /// <summary>The support agent working it.</summary>
    public Guid? AssigneeId { get; set; }
    /// <summary>The resolution note.</summary>
    public required string Resolution { get; set; }
    /// <summary>Whether support verified it.</summary>
    public bool Verified { get; set; }
    /// <summary>When it was filed.</summary>
    public DateTimeOffset CreatedAt { get; set; }
    /// <summary>When it last changed.</summary>
    public DateTimeOffset UpdatedAt { get; set; }
    /// <summary>When it was resolved.</summary>
    public DateTimeOffset? ResolvedAt { get; set; }
}

/// <summary>A row of `admin.complaint_comments`: an internal support note.</summary>
public sealed class ComplaintCommentRecord
{
    /// <summary>The id.</summary>
    public Guid Id { get; set; }
    /// <summary>The complaint.</summary>
    public Guid ComplaintId { get; set; }
    /// <summary>The admin who wrote it.</summary>
    public Guid AuthorId { get; set; }
    /// <summary>The note.</summary>
    public required string Body { get; set; }
    /// <summary>When.</summary>
    public DateTimeOffset At { get; set; }
}

/// <summary>A row of `admin.stats_bookings_daily`: bookings requested and completed on a Dhaka day.</summary>
public sealed class BookingDayRecord
{
    /// <summary>The Dhaka calendar date.</summary>
    public DateOnly Day { get; set; }
    /// <summary>Requests that day.</summary>
    public int Requested { get; set; }
    /// <summary>Completions that day.</summary>
    public int Completed { get; set; }
}

/// <summary>A row of `admin.stats_providers`: a provider's status and level for the dashboard.</summary>
public sealed class StatsProviderRecord
{
    /// <summary>The provider.</summary>
    public Guid ProviderId { get; set; }
    /// <summary>The account status.</summary>
    public required string Status { get; set; }
    /// <summary>The verification level.</summary>
    public int Level { get; set; }
}

/// <summary>Maps the Admin records to the `admin` schema.</summary>
public sealed class AdminConfiguration :
    IEntityTypeConfiguration<SettingRecord>, IEntityTypeConfiguration<ComplaintRecord>, IEntityTypeConfiguration<ComplaintCommentRecord>,
    IEntityTypeConfiguration<BookingDayRecord>, IEntityTypeConfiguration<StatsProviderRecord>
{
    /// <inheritdoc />
    public void Configure(EntityTypeBuilder<SettingRecord> builder)
    {
        builder.ToTable("settings", Schemas.Admin);
        builder.HasKey(s => s.Key);
    }

    /// <inheritdoc />
    public void Configure(EntityTypeBuilder<ComplaintRecord> builder)
    {
        builder.ToTable("complaints", Schemas.Admin);
        builder.HasKey(c => c.Id);
        builder.Property(c => c.TicketNumber).ValueGeneratedOnAdd();
    }

    /// <inheritdoc />
    public void Configure(EntityTypeBuilder<ComplaintCommentRecord> builder)
    {
        builder.ToTable("complaint_comments", Schemas.Admin);
        builder.HasKey(c => c.Id);
    }

    /// <inheritdoc />
    public void Configure(EntityTypeBuilder<BookingDayRecord> builder)
    {
        builder.ToTable("stats_bookings_daily", Schemas.Admin);
        builder.HasKey(d => d.Day);
    }

    /// <inheritdoc />
    public void Configure(EntityTypeBuilder<StatsProviderRecord> builder)
    {
        builder.ToTable("stats_providers", Schemas.Admin);
        builder.HasKey(p => p.ProviderId);
    }
}
