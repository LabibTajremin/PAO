using Microsoft.EntityFrameworkCore;
using Microsoft.EntityFrameworkCore.Metadata.Builders;

namespace PAO.EF.Verification;

/// <summary>Maps <see cref="VerificationItemRecord"/> to `verification.items`.</summary>
public sealed class VerificationItemConfiguration : IEntityTypeConfiguration<VerificationItemRecord>
{
    /// <inheritdoc />
    public void Configure(EntityTypeBuilder<VerificationItemRecord> builder)
    {
        builder.ToTable("items", Schemas.Verification);
        builder.HasKey(i => new { i.ProviderId, i.ItemType });
        builder.Property(i => i.Fields).HasColumnType("jsonb");
    }
}

/// <summary>Maps <see cref="VerificationDocumentRecord"/> to `verification.documents`.</summary>
public sealed class VerificationDocumentConfiguration : IEntityTypeConfiguration<VerificationDocumentRecord>
{
    /// <inheritdoc />
    public void Configure(EntityTypeBuilder<VerificationDocumentRecord> builder)
    {
        builder.ToTable("documents", Schemas.Verification);
        builder.HasKey(d => d.Id);
    }
}

/// <summary>Maps <see cref="NidRecord"/> to `verification.nid_records`.</summary>
public sealed class NidConfiguration : IEntityTypeConfiguration<NidRecord>
{
    /// <inheritdoc />
    public void Configure(EntityTypeBuilder<NidRecord> builder)
    {
        builder.ToTable("nid_records", Schemas.Verification);
        builder.HasKey(n => n.ProviderId);
    }
}

/// <summary>Maps <see cref="BlockedNidRecord"/> to `verification.blocked_nids`.</summary>
public sealed class BlockedNidConfiguration : IEntityTypeConfiguration<BlockedNidRecord>
{
    /// <inheritdoc />
    public void Configure(EntityTypeBuilder<BlockedNidRecord> builder)
    {
        builder.ToTable("blocked_nids", Schemas.Verification);
        builder.HasKey(b => b.NidHash);
    }
}

/// <summary>Maps <see cref="VerificationLevelRecord"/> to `verification.levels`.</summary>
public sealed class VerificationLevelConfiguration : IEntityTypeConfiguration<VerificationLevelRecord>
{
    /// <inheritdoc />
    public void Configure(EntityTypeBuilder<VerificationLevelRecord> builder)
    {
        builder.ToTable("levels", Schemas.Verification);
        builder.HasKey(l => l.ProviderId);
    }
}

/// <summary>Maps <see cref="Level2SessionRecord"/> to `verification.level2_sessions`.</summary>
public sealed class Level2SessionConfiguration : IEntityTypeConfiguration<Level2SessionRecord>
{
    /// <inheritdoc />
    public void Configure(EntityTypeBuilder<Level2SessionRecord> builder)
    {
        builder.ToTable("level2_sessions", Schemas.Verification);
        builder.HasKey(s => s.Id);
        builder.Property(s => s.Checklist).HasColumnType("jsonb");
    }
}

/// <summary>Maps <see cref="ExpiryReminderRecord"/> to `verification.reminders_sent`.</summary>
public sealed class ExpiryReminderConfiguration : IEntityTypeConfiguration<ExpiryReminderRecord>
{
    /// <inheritdoc />
    public void Configure(EntityTypeBuilder<ExpiryReminderRecord> builder)
    {
        builder.ToTable("reminders_sent", Schemas.Verification);
        builder.HasKey(r => new { r.ProviderId, r.ItemType, r.ExpiresAt, r.DaysBefore });
    }
}

/// <summary>Maps <see cref="ClosedAccountRecord"/> to `verification.closed_accounts`.</summary>
public sealed class ClosedAccountConfiguration : IEntityTypeConfiguration<ClosedAccountRecord>
{
    /// <inheritdoc />
    public void Configure(EntityTypeBuilder<ClosedAccountRecord> builder)
    {
        builder.ToTable("closed_accounts", Schemas.Verification);
        builder.HasKey(c => c.ProviderId);
    }
}
