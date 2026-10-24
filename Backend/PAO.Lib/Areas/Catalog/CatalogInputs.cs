using PAO.Lib.Common;

namespace PAO.Lib.Areas.Catalog;

/// <summary>The body of createCategory and updateCategory.</summary>
public sealed record CategoryInput
{
    /// <summary>The name.</summary>
    public required Text Name { get; init; }
    /// <summary>The icon key.</summary>
    public required string IconKey { get; init; }
    /// <summary>The sort order; 0 when absent.</summary>
    public int? SortOrder { get; init; }
    /// <summary>Whether published; false when absent.</summary>
    public bool? Published { get; init; }
}

/// <summary>The body of createService and updateService.</summary>
public sealed record ServiceInput
{
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
    public bool? WomenProvidersOnly { get; init; }
    /// <summary>Whether Level 2 is needed first.</summary>
    public bool? RequiresLevel2 { get; init; }
    /// <summary>The Level 2 checklist.</summary>
    public IReadOnlyList<Text>? Level2Checklist { get; init; }
    /// <summary>Whether published.</summary>
    public bool? Published { get; init; }
}

/// <summary>The body of createSubService and updateSubService.</summary>
public sealed record SubServiceInput
{
    /// <summary>The service id.</summary>
    public required Guid ServiceId { get; init; }
    /// <summary>The name.</summary>
    public required Text Name { get; init; }
    /// <summary>The description.</summary>
    public Text? Description { get; init; }
    /// <summary>The inclusions.</summary>
    public IReadOnlyList<Text>? Inclusions { get; init; }
    /// <summary>The exclusions.</summary>
    public IReadOnlyList<Text>? Exclusions { get; init; }
    /// <summary>The unit.</summary>
    public required string Unit { get; init; }
    /// <summary>The maximum quantity; 1 when absent.</summary>
    public int? MaxQuantity { get; init; }
    /// <summary>The first price in paisa; required on create, ignored on update.</summary>
    public long? InitialPrice { get; init; }
    /// <summary>Whether published.</summary>
    public bool? Published { get; init; }
}

/// <summary>The body of changePrice.</summary>
public sealed record PriceInput
{
    /// <summary>The new amount in paisa.</summary>
    public required long Amount { get; init; }
}
