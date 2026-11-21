using Microsoft.EntityFrameworkCore;
using Microsoft.EntityFrameworkCore.Metadata.Builders;

namespace PAO.EF.Catalog;

/// <summary>A row of `catalog.banners`.</summary>
public sealed class BannerRecord
{
    /// <summary>The id.</summary>
    public Guid Id { get; set; }
    /// <summary>The English title.</summary>
    public required string TitleEn { get; set; }
    /// <summary>The Bangla title.</summary>
    public required string TitleBn { get; set; }
    /// <summary>The English subtitle; null with the Bangla one.</summary>
    public string? SubtitleEn { get; set; }
    /// <summary>The Bangla subtitle.</summary>
    public string? SubtitleBn { get; set; }
    /// <summary>The https image URL, if any.</summary>
    public string? ImageUrl { get; set; }
    /// <summary>The service the banner opens, if any.</summary>
    public Guid? ServiceId { get; set; }
    /// <summary>The sort order.</summary>
    public int SortOrder { get; set; }
    /// <summary>Whether published.</summary>
    public bool Published { get; set; }
}

/// <summary>Maps <see cref="BannerRecord"/> to `catalog.banners`.</summary>
public sealed class BannerConfiguration : IEntityTypeConfiguration<BannerRecord>
{
    /// <inheritdoc />
    public void Configure(EntityTypeBuilder<BannerRecord> builder)
    {
        builder.ToTable("banners", Schemas.Catalog);
        builder.HasKey(b => b.Id);
    }
}
