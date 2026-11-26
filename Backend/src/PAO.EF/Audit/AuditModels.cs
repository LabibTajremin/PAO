using Microsoft.EntityFrameworkCore;
using Microsoft.EntityFrameworkCore.Metadata.Builders;

namespace PAO.EF.Audit;

/// <summary>A row of `audit.entries`; triggers reject UPDATE, DELETE and TRUNCATE (PRD §6.4).</summary>
public sealed class Entry
{
    /// <summary>The id.</summary>
    public Guid Id { get; set; }
    /// <summary>When it happened.</summary>
    public DateTimeOffset At { get; set; }
    /// <summary>Who acted; null for system actions.</summary>
    public Guid? ActorId { get; set; }
    /// <summary>The actor role.</summary>
    public string ActorRole { get; set; } = string.Empty;
    /// <summary>The action, e.g. `verification.item_approved`.</summary>
    public string Action { get; set; } = string.Empty;
    /// <summary>The subject type.</summary>
    public string SubjectType { get; set; } = string.Empty;
    /// <summary>The subject id.</summary>
    public string SubjectId { get; set; } = string.Empty;
    /// <summary>The reason.</summary>
    public string Reason { get; set; } = string.Empty;
    /// <summary>The state before, as JSON text.</summary>
    public string? Before { get; set; }
    /// <summary>The state after, as JSON text.</summary>
    public string? After { get; set; }
    /// <summary>The event the entry was written from; unique, so redelivery adds nothing.</summary>
    public Guid? EventId { get; set; }
}

/// <summary>Maps <see cref="Entry"/> to `audit.entries`.</summary>
public sealed class EntryConfiguration : IEntityTypeConfiguration<Entry>
{
    /// <inheritdoc />
    public void Configure(EntityTypeBuilder<Entry> builder)
    {
        builder.ToTable("entries", Schemas.Audit);
        builder.HasKey(e => e.Id);
        builder.Property(e => e.Before).HasColumnType("jsonb");
        builder.Property(e => e.After).HasColumnType("jsonb");
    }
}
