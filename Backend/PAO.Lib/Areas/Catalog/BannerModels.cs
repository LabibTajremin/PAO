using System.Text.Json.Serialization;
using PAO.EF.Catalog;
using PAO.Lib.Common;
using PAO.Lib.Mapping;

namespace PAO.Lib.Areas.Catalog;

/// <summary>The body of createBanner and updateBanner.</summary>
public sealed record BannerInput
{
    /// <summary>The title.</summary>
    public required Text Title { get; init; }
    /// <summary>The subtitle, if any.</summary>
    public Text? Subtitle { get; init; }
    /// <summary>The https image URL, if any.</summary>
    public string? ImageUrl { get; init; }
    /// <summary>The service the banner opens, if any.</summary>
    public Guid? ServiceId { get; init; }
    /// <summary>The sort order; 0 when absent.</summary>
    public int? SortOrder { get; init; }
    /// <summary>Whether published; false when absent.</summary>
    public bool? Published { get; init; }
}

/// <summary>The API shape of a home banner.</summary>
public sealed record BannerView
{
    /// <summary>The id.</summary>
    public required Guid Id { get; init; }
    /// <summary>The title.</summary>
    public required Text Title { get; init; }
    /// <summary>The subtitle; absent when there is none.</summary>
    [JsonIgnore(Condition = JsonIgnoreCondition.WhenWritingNull)]
    public Text? Subtitle { get; init; }
    /// <summary>The image URL; absent when there is none.</summary>
    [JsonIgnore(Condition = JsonIgnoreCondition.WhenWritingNull)]
    public string? ImageUrl { get; init; }
    /// <summary>The service it opens; absent when none.</summary>
    [JsonIgnore(Condition = JsonIgnoreCondition.WhenWritingNull)]
    public Guid? ServiceId { get; init; }
    /// <summary>The sort order.</summary>
    public required int SortOrder { get; init; }
    /// <summary>Whether published.</summary>
    public required bool Published { get; init; }
}

/// <summary>The API shape of a banner list.</summary>
public sealed record BannerListView
{
    /// <summary>The banners in display order.</summary>
    public required IReadOnlyList<BannerView> Banners { get; init; }
}

/// <summary>Banner maps: rows to views, an id and input to a view.</summary>
public sealed class BannerMappingProfile : IMappingProfile
{
    /// <inheritdoc />
    public void Configure(MappingRegistry registry) => registry
        .Add<BannerRecord, BannerView>((b, _) => new BannerView
        {
            Id = b.Id,
            Title = new Text { En = b.TitleEn, Bn = b.TitleBn },
            Subtitle = b.SubtitleEn is null ? null : new Text { En = b.SubtitleEn, Bn = b.SubtitleBn! },
            ImageUrl = b.ImageUrl,
            ServiceId = b.ServiceId,
            SortOrder = b.SortOrder,
            Published = b.Published,
        })
        .Add<(Guid Id, BannerInput Input), BannerView>((x, _) => new BannerView
        {
            Id = x.Id,
            Title = x.Input.Title,
            Subtitle = x.Input.Subtitle,
            ImageUrl = x.Input.ImageUrl,
            ServiceId = x.Input.ServiceId,
            SortOrder = x.Input.SortOrder ?? 0,
            Published = x.Input.Published ?? false,
        });
}
