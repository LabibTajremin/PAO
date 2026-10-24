namespace PAO.EF.Catalog;

/// <summary>A row of `catalog.categories`.</summary>
public sealed class CategoryRecord
{
    /// <summary>The id.</summary>
    public Guid Id { get; set; }
    /// <summary>The English name.</summary>
    public required string NameEn { get; set; }
    /// <summary>The Bangla name.</summary>
    public required string NameBn { get; set; }
    /// <summary>The icon key.</summary>
    public required string IconKey { get; set; }
    /// <summary>The sort order.</summary>
    public int SortOrder { get; set; }
    /// <summary>Whether published.</summary>
    public bool Published { get; set; }
}

/// <summary>A row of `catalog.services`.</summary>
public sealed class ServiceRecord
{
    /// <summary>The id.</summary>
    public Guid Id { get; set; }
    /// <summary>The category id.</summary>
    public Guid CategoryId { get; set; }
    /// <summary>The English name.</summary>
    public required string NameEn { get; set; }
    /// <summary>The Bangla name.</summary>
    public required string NameBn { get; set; }
    /// <summary>The icon key.</summary>
    public required string IconKey { get; set; }
    /// <summary>The service model.</summary>
    public required string ServiceModel { get; set; }
    /// <summary>The required verification level.</summary>
    public int RequiredLevel { get; set; }
    /// <summary>The search radius in metres.</summary>
    public int SearchRadiusM { get; set; }
    /// <summary>Whether only women providers serve it.</summary>
    public bool WomenProvidersOnly { get; set; }
    /// <summary>Whether Level 2 is needed before the first booking.</summary>
    public bool RequiresLevel2 { get; set; }
    /// <summary>The Level 2 checklist as stored JSON (`[{"en","bn"}]`).</summary>
    public required string Level2Checklist { get; set; }
    /// <summary>The sort order.</summary>
    public int SortOrder { get; set; }
    /// <summary>Whether published.</summary>
    public bool Published { get; set; }
}

/// <summary>A row of `catalog.sub_services`.</summary>
public sealed class SubServiceRecord
{
    /// <summary>The id.</summary>
    public Guid Id { get; set; }
    /// <summary>The service id.</summary>
    public Guid ServiceId { get; set; }
    /// <summary>The English name.</summary>
    public required string NameEn { get; set; }
    /// <summary>The Bangla name.</summary>
    public required string NameBn { get; set; }
    /// <summary>The description as stored JSON (`{"en","bn"}`).</summary>
    public required string Description { get; set; }
    /// <summary>The inclusions as stored JSON.</summary>
    public required string Inclusions { get; set; }
    /// <summary>The exclusions as stored JSON.</summary>
    public required string Exclusions { get; set; }
    /// <summary>The price unit.</summary>
    public required string Unit { get; set; }
    /// <summary>The maximum quantity.</summary>
    public int MaxQuantity { get; set; }
    /// <summary>The sort order.</summary>
    public int SortOrder { get; set; }
    /// <summary>Whether published.</summary>
    public bool Published { get; set; }
    /// <summary>The current price version.</summary>
    public Guid? CurrentPriceVersionId { get; set; }
}

/// <summary>A row of `catalog.price_versions`; rows are never updated.</summary>
public sealed class PriceVersionRecord
{
    /// <summary>The id.</summary>
    public Guid Id { get; set; }
    /// <summary>The sub-service id.</summary>
    public Guid SubServiceId { get; set; }
    /// <summary>The amount in paisa.</summary>
    public long AmountPaisa { get; set; }
    /// <summary>When it took effect.</summary>
    public DateTimeOffset EffectiveFrom { get; set; }
    /// <summary>The admin who set it; the nil UUID for the seed.</summary>
    public Guid CreatedBy { get; set; }
}

/// <summary>The single row of `catalog.catalog_version`.</summary>
public sealed class CatalogVersionRecord
{
    /// <summary>Always true; the table holds one row.</summary>
    public bool Singleton { get; set; }
    /// <summary>The version, bumped on every edit.</summary>
    public long Version { get; set; }
}
