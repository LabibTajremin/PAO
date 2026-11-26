using Microsoft.EntityFrameworkCore;
using Microsoft.EntityFrameworkCore.Metadata.Builders;

namespace PAO.EF.Admin;

/// <summary>A row of `admin.artwork_slots`: the image an artwork slot shows (ADR-0040).</summary>
public sealed class ArtworkRecord
{
    /// <summary>The slot key.</summary>
    public required string Key { get; set; }
    /// <summary>The image shown; null falls back to the app's bundled seed.</summary>
    public string? Url { get; set; }
    /// <summary>The image type.</summary>
    public string? ContentType { get; set; }
    /// <summary>The seed image in storage, put back by a reset.</summary>
    public string? SeedUrl { get; set; }
    /// <summary>Bumped on every change, so apps refresh their cache.</summary>
    public int Version { get; set; }
    /// <summary>Whether an admin uploaded the image; seeding leaves it alone.</summary>
    public bool Replaced { get; set; }
    /// <summary>When it last changed.</summary>
    public DateTimeOffset UpdatedAt { get; set; }
    /// <summary>Who changed it last; null for seeding.</summary>
    public Guid? UpdatedBy { get; set; }
}

/// <summary>Maps <see cref="ArtworkRecord"/> to `admin.artwork_slots`.</summary>
public sealed class ArtworkConfiguration : IEntityTypeConfiguration<ArtworkRecord>
{
    /// <inheritdoc />
    public void Configure(EntityTypeBuilder<ArtworkRecord> builder)
    {
        builder.ToTable("artwork_slots", Schemas.Admin);
        builder.HasKey(a => a.Key);
    }
}
