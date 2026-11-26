using PAO.Lib.Common;

namespace PAO.Lib.Areas.Catalog;

/// <summary>A bookable item with its current price; without a price it is the item as written.</summary>
public sealed record SubServiceNode
{
    /// <summary>The id.</summary>
    public required Guid Id { get; init; }
    /// <summary>The service id.</summary>
    public required Guid ServiceId { get; init; }
    /// <summary>The name.</summary>
    public required Text Name { get; init; }
    /// <summary>The description; both texts empty when there is none.</summary>
    public required Text Description { get; init; }
    /// <summary>What the job includes.</summary>
    public required IReadOnlyList<Text> Inclusions { get; init; }
    /// <summary>What the job excludes.</summary>
    public required IReadOnlyList<Text> Exclusions { get; init; }
    /// <summary>The unit one quantity means.</summary>
    public required string Unit { get; init; }
    /// <summary>The maximum quantity per booking.</summary>
    public required int MaxQuantity { get; init; }
    /// <summary>The sort order.</summary>
    public required int SortOrder { get; init; }
    /// <summary>Whether published.</summary>
    public required bool Published { get; init; }
    /// <summary>The current price version.</summary>
    public Guid PriceVersionId { get; init; }
    /// <summary>The current price in paisa.</summary>
    public long Price { get; init; }
}

/// <summary>A trade with the rules other areas enforce, and its sub-services.</summary>
public sealed record ServiceNode
{
    /// <summary>The id.</summary>
    public required Guid Id { get; init; }
    /// <summary>The category id.</summary>
    public required Guid CategoryId { get; init; }
    /// <summary>The name.</summary>
    public required Text Name { get; init; }
    /// <summary>The icon key.</summary>
    public required string IconKey { get; init; }
    /// <summary>An uploaded or linked icon in our public bucket (ADR-0039); null uses the icon key.</summary>
    public string? IconUrl { get; init; }
    /// <summary>The service model.</summary>
    public required string Model { get; init; }
    /// <summary>The required verification level.</summary>
    public required int RequiredLevel { get; init; }
    /// <summary>The search radius in metres.</summary>
    public required int SearchRadiusM { get; init; }
    /// <summary>Whether only women providers serve it.</summary>
    public required bool WomenProvidersOnly { get; init; }
    /// <summary>Whether Level 2 is needed before the first booking.</summary>
    public required bool RequiresLevel2 { get; init; }
    /// <summary>What the Level 2 session checks.</summary>
    public required IReadOnlyList<Text> Level2Checklist { get; init; }
    /// <summary>The ordering rules of a scheduled-delivery service; null for the other models.</summary>
    public ServiceSchedule? Schedule { get; init; }
    /// <summary>The sort order.</summary>
    public required int SortOrder { get; init; }
    /// <summary>Whether published.</summary>
    public required bool Published { get; init; }
    /// <summary>The sub-services, in sort order.</summary>
    public IReadOnlyList<SubServiceNode> SubServices { get; init; } = [];
}

/// <summary>A group of services.</summary>
public sealed record CategoryNode
{
    /// <summary>The id.</summary>
    public required Guid Id { get; init; }
    /// <summary>The name.</summary>
    public required Text Name { get; init; }
    /// <summary>The icon key.</summary>
    public required string IconKey { get; init; }
    /// <summary>An uploaded or linked icon in our public bucket (ADR-0039); null uses the icon key.</summary>
    public string? IconUrl { get; init; }
    /// <summary>The sort order.</summary>
    public required int SortOrder { get; init; }
    /// <summary>Whether published.</summary>
    public required bool Published { get; init; }
    /// <summary>The services, in sort order.</summary>
    public IReadOnlyList<ServiceNode> Services { get; init; } = [];
}

/// <summary>The catalog tree at one version.</summary>
public sealed record CatalogSnapshot
{
    /// <summary>The catalog version.</summary>
    public required long Version { get; init; }
    /// <summary>The categories, in sort order.</summary>
    public required IReadOnlyList<CategoryNode> Categories { get; init; }
}

/// <summary>One immutable price row.</summary>
public sealed record PriceVersionInfo
{
    /// <summary>The id.</summary>
    public required Guid Id { get; init; }
    /// <summary>The sub-service id.</summary>
    public required Guid SubServiceId { get; init; }
    /// <summary>The amount in paisa.</summary>
    public required long Amount { get; init; }
    /// <summary>When it took effect.</summary>
    public required DateTimeOffset EffectiveFrom { get; init; }
    /// <summary>The admin who set it; the nil UUID for the seed.</summary>
    public required Guid CreatedBy { get; init; }
}

/// <summary>Reasons the catalog use cases raise; only the HTTP edge maps them to API errors.</summary>
public static class CatalogReasons
{
    /// <summary>No category, service or sub-service has the id.</summary>
    public const string NotFound = "catalog.not_found";
    /// <summary>The item breaks a catalog rule (names, icon, model, level, radius, unit).</summary>
    public const string Invalid = "catalog.invalid";
    /// <summary>A price below zero, or none where one is needed.</summary>
    public const string PriceNegative = "catalog.price_negative";
    /// <summary>An icon URL that is not one of the icons we stored (ADR-0039).</summary>
    public const string IconNotStored = "catalog.icon_not_stored";
    /// <summary>The icon file is larger than its format allows.</summary>
    public const string IconTooLarge = "catalog.icon_too_large";
    /// <summary>The icon file is not a well-formed SVG, PNG or WebP of the stated type.</summary>
    public const string IconUnreadable = "catalog.icon_unreadable";
    /// <summary>A PNG or WebP icon whose sides differ.</summary>
    public const string IconNotSquare = "catalog.icon_not_square";
    /// <summary>A PNG or WebP icon smaller than 96 x 96.</summary>
    public const string IconTooSmall = "catalog.icon_too_small";
    /// <summary>A PNG or WebP icon without an alpha channel.</summary>
    public const string IconOpaque = "catalog.icon_opaque";
    /// <summary>The icon link could not be downloaded, or points at a private address.</summary>
    public const string IconLinkFailed = "catalog.icon_link_failed";
}
