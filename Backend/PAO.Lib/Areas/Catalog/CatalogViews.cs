using System.Text.Json.Serialization;
using PAO.Lib.Common;

namespace PAO.Lib.Areas.Catalog;

/// <summary>The API shape of a sub-service with its current price.</summary>
public sealed record SubServiceView
{
    /// <summary>The id.</summary>
    public required Guid Id { get; init; }
    /// <summary>The service id.</summary>
    public required Guid ServiceId { get; init; }
    /// <summary>The name.</summary>
    public required Text Name { get; init; }
    /// <summary>The description; absent when there is none (seeded items have none).</summary>
    [JsonIgnore(Condition = JsonIgnoreCondition.WhenWritingNull)]
    public Text? Description { get; init; }
    /// <summary>The inclusions.</summary>
    public required IReadOnlyList<Text> Inclusions { get; init; }
    /// <summary>The exclusions.</summary>
    public required IReadOnlyList<Text> Exclusions { get; init; }
    /// <summary>The unit.</summary>
    public required string Unit { get; init; }
    /// <summary>The current price in paisa.</summary>
    public required long Price { get; init; }
    /// <summary>The current price version.</summary>
    public required Guid PriceVersionId { get; init; }
    /// <summary>The maximum quantity.</summary>
    public required int MaxQuantity { get; init; }
    /// <summary>Whether published.</summary>
    public required bool Published { get; init; }
}

/// <summary>The API shape of a service with its sub-services.</summary>
public sealed record ServiceView
{
    /// <summary>The id.</summary>
    public required Guid Id { get; init; }
    /// <summary>The category id.</summary>
    public required Guid CategoryId { get; init; }
    /// <summary>The name.</summary>
    public required Text Name { get; init; }
    /// <summary>The icon key.</summary>
    public required string IconKey { get; init; }
    /// <summary>The service model.</summary>
    public required string ServiceModel { get; init; }
    /// <summary>The required level.</summary>
    public required int RequiredLevel { get; init; }
    /// <summary>The search radius in metres.</summary>
    public required int SearchRadiusM { get; init; }
    /// <summary>Whether only women providers serve it.</summary>
    public required bool WomenProvidersOnly { get; init; }
    /// <summary>Whether Level 2 is needed first.</summary>
    public required bool RequiresLevel2 { get; init; }
    /// <summary>The Level 2 checklist.</summary>
    public required IReadOnlyList<Text> Level2Checklist { get; init; }
    /// <summary>Whether published.</summary>
    public required bool Published { get; init; }
    /// <summary>The sub-services.</summary>
    public required IReadOnlyList<SubServiceView> SubServices { get; init; }
}

/// <summary>The API shape of a category with its services.</summary>
public sealed record CategoryView
{
    /// <summary>The id.</summary>
    public required Guid Id { get; init; }
    /// <summary>The name.</summary>
    public required Text Name { get; init; }
    /// <summary>The icon key.</summary>
    public required string IconKey { get; init; }
    /// <summary>The sort order.</summary>
    public required int SortOrder { get; init; }
    /// <summary>Whether published.</summary>
    public required bool Published { get; init; }
    /// <summary>The services.</summary>
    public required IReadOnlyList<ServiceView> Services { get; init; }
}

/// <summary>The API shape of the catalog tree.</summary>
public sealed record CatalogTreeView
{
    /// <summary>The version, bumped on every change.</summary>
    public required long Version { get; init; }
    /// <summary>The categories.</summary>
    public required IReadOnlyList<CategoryView> Categories { get; init; }
}

/// <summary>The API shape of a search.</summary>
public sealed record CatalogSearchView
{
    /// <summary>Matching services, best first.</summary>
    public required IReadOnlyList<ServiceView> Services { get; init; }
    /// <summary>Matching sub-services, best first.</summary>
    public required IReadOnlyList<SubServiceView> SubServices { get; init; }
}

/// <summary>The API shape of a price version.</summary>
public sealed record PriceVersionView
{
    /// <summary>The id.</summary>
    public required Guid Id { get; init; }
    /// <summary>The sub-service id.</summary>
    public required Guid SubServiceId { get; init; }
    /// <summary>The amount in paisa.</summary>
    public required long Amount { get; init; }
    /// <summary>When it took effect (ISO 8601).</summary>
    public required string EffectiveFrom { get; init; }
    /// <summary>Who set it.</summary>
    public required Guid CreatedBy { get; init; }
}

/// <summary>The API shape of a price history.</summary>
public sealed record PriceHistoryView
{
    /// <summary>The versions, newest first.</summary>
    public required IReadOnlyList<PriceVersionView> Items { get; init; }
}
