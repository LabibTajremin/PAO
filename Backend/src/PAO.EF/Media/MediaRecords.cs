using Microsoft.EntityFrameworkCore;
using Microsoft.EntityFrameworkCore.Metadata.Builders;

namespace PAO.EF.Media;

/// <summary>A row of `media.objects`: an upload to private storage and its state.</summary>
public sealed class MediaObjectRecord
{
    /// <summary>The id.</summary>
    public Guid Id { get; set; }
    /// <summary>The uploading account.</summary>
    public Guid OwnerId { get; set; }
    /// <summary>The purpose.</summary>
    public required string Purpose { get; set; }
    /// <summary>The declared content type.</summary>
    public required string ContentType { get; set; }
    /// <summary>The declared size in bytes.</summary>
    public long SizeBytes { get; set; }
    /// <summary>The bucket.</summary>
    public required string Bucket { get; set; }
    /// <summary>The object key.</summary>
    public required string ObjectKey { get; set; }
    /// <summary>`pending` or `confirmed`.</summary>
    public required string Status { get; set; }
    /// <summary>Whether a record references it.</summary>
    public bool Attached { get; set; }
    /// <summary>When the upload was requested.</summary>
    public DateTimeOffset CreatedAt { get; set; }
    /// <summary>When it was confirmed.</summary>
    public DateTimeOffset? ConfirmedAt { get; set; }
}

/// <summary>Maps <see cref="MediaObjectRecord"/> to `media.objects`.</summary>
public sealed class MediaObjectConfiguration : IEntityTypeConfiguration<MediaObjectRecord>
{
    /// <inheritdoc />
    public void Configure(EntityTypeBuilder<MediaObjectRecord> builder)
    {
        builder.ToTable("objects", Schemas.Media);
        builder.HasKey(o => o.Id);
    }
}
