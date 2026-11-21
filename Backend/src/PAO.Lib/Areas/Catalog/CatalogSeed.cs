using PAO.Lib.Common;

namespace PAO.Lib.Areas.Catalog;

/// <summary>A sub-service of the seed catalog, its price in paisa.</summary>
public sealed record SeedSubService
{
    /// <summary>The key its id derives from.</summary>
    public required string Key { get; init; }
    /// <summary>The name.</summary>
    public required Text Name { get; init; }
    /// <summary>The unit.</summary>
    public required string Unit { get; init; }
    /// <summary>The price in paisa.</summary>
    public required long PricePaisa { get; init; }
    /// <summary>The maximum quantity.</summary>
    public required int MaxQuantity { get; init; }
}

/// <summary>A service of the seed catalog.</summary>
public sealed record SeedService
{
    /// <summary>The key its id derives from.</summary>
    public required string Key { get; init; }
    /// <summary>The name.</summary>
    public required Text Name { get; init; }
    /// <summary>The icon key.</summary>
    public required string Icon { get; init; }
    /// <summary>The service model.</summary>
    public required string Model { get; init; }
    /// <summary>The required level.</summary>
    public required int RequiredLevel { get; init; }
    /// <summary>The search radius in metres.</summary>
    public required int SearchRadiusM { get; init; }
    /// <summary>Whether only women providers serve it.</summary>
    public bool WomenProvidersOnly { get; init; }
    /// <summary>Whether Level 2 is needed first.</summary>
    public bool RequiresLevel2 { get; init; }
    /// <summary>The Level 2 checklist.</summary>
    public IReadOnlyList<Text> Level2Checklist { get; init; } = [];
    /// <summary>The sub-services, in file order.</summary>
    public IReadOnlyList<SeedSubService> SubServices { get; init; } = [];
}

/// <summary>A category of the seed catalog (`seed/catalog.yaml`).</summary>
public sealed record SeedCategory
{
    /// <summary>The key its id derives from.</summary>
    public required string Key { get; init; }
    /// <summary>The name.</summary>
    public required Text Name { get; init; }
    /// <summary>The icon key.</summary>
    public required string Icon { get; init; }
    /// <summary>The services, in file order.</summary>
    public IReadOnlyList<SeedService> Services { get; init; } = [];
}
