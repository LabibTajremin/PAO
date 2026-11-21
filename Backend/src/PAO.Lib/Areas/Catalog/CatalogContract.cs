using PAO.Lib.Common;
using PAO.Lib.Events;

namespace PAO.Lib.Areas.Catalog;

/// <summary>How a service is sold (PRD §4).</summary>
public static class ServiceModel
{
    /// <summary>The `"on_demand"` value.</summary>
    public const string OnDemand = "on_demand";
    /// <summary>The `"duration_hire"` value.</summary>
    public const string DurationHire = "duration_hire";
    /// <summary>The `"listing"` value.</summary>
    public const string Listing = "listing";
    /// <summary>The `"partner_referral"` value.</summary>
    public const string PartnerReferral = "partner_referral";
}

/// <summary>What a price is per.</summary>
public static class PriceUnit
{
    /// <summary>The `"job"` value.</summary>
    public const string Job = "job";
    /// <summary>The `"unit"` value.</summary>
    public const string Unit = "unit";
    /// <summary>The `"hour"` value.</summary>
    public const string Hour = "hour";
    /// <summary>The `"day"` value.</summary>
    public const string Day = "day";
}

/// <summary>A service with its booking rules.</summary>
public sealed record CatalogService
{
    /// <summary>The id.</summary>
    public required Guid Id { get; init; }
    /// <summary>The category id.</summary>
    public required Guid CategoryId { get; init; }
    /// <summary>The name.</summary>
    public required Text Name { get; init; }
    /// <summary>The model.</summary>
    public required string Model { get; init; }
    /// <summary>The required level.</summary>
    public required int RequiredLevel { get; init; }
    /// <summary>The search radius m.</summary>
    public required int SearchRadiusM { get; init; }
    /// <summary>Whether women providers only.</summary>
    public required bool WomenProvidersOnly { get; init; }
    /// <summary>Whether requires level 2.</summary>
    public required bool RequiresLevel2 { get; init; }
    /// <summary>The level 2 checklist.</summary>
    public required IReadOnlyList<Text> Level2Checklist { get; init; }
    /// <summary>Whether published.</summary>
    public required bool Published { get; init; }
}

/// <summary>The current price of a sub-service, copied into bookings (PRD §4).</summary>
public sealed record PriceSnapshot
{
    /// <summary>The sub service id.</summary>
    public required Guid SubServiceId { get; init; }
    /// <summary>The service id.</summary>
    public required Guid ServiceId { get; init; }
    /// <summary>The price version id.</summary>
    public required Guid PriceVersionId { get; init; }
    /// <summary>The name.</summary>
    public required Text Name { get; init; }
    /// <summary>The unit.</summary>
    public required string Unit { get; init; }
    /// <summary>The amount paisa.</summary>
    public required long AmountPaisa { get; init; }
    /// <summary>The max quantity.</summary>
    public required int MaxQuantity { get; init; }
    /// <summary>Whether published.</summary>
    public required bool Published { get; init; }
}

/// <summary>The Catalog area's error reasons.</summary>
public static class CatalogErrors
{
    /// <summary>The `"catalog.service_not_found"` value.</summary>
    public const string ServiceNotFound = "catalog.service_not_found";
    /// <summary>The `"catalog.sub_service_not_found"` value.</summary>
    public const string SubServiceNotFound = "catalog.sub_service_not_found";
}

/// <summary>Names of the events the Catalog area publishes.</summary>
public static class CatalogEvents
{
    /// <summary>The `"catalog.CatalogChanged"` value.</summary>
    public const string CatalogChanged = "catalog.CatalogChanged";
    /// <summary>The `"catalog.PriceChanged"` value.</summary>
    public const string PriceChanged = "catalog.PriceChanged";
}

/// <summary>The published catalog changed; caches keyed by version are stale.</summary>
public sealed record CatalogChanged : IDomainEvent
{
    /// <summary>The name.</summary>
    public string Name { get; } = CatalogEvents.CatalogChanged;
    /// <summary>The version.</summary>
    public required long Version { get; init; }
}

/// <summary>A sub-service got a new price version.</summary>
public sealed record PriceChanged : IDomainEvent
{
    /// <summary>The name.</summary>
    public string Name { get; } = CatalogEvents.PriceChanged;
    /// <summary>The sub service id.</summary>
    public required Guid SubServiceId { get; init; }
    /// <summary>The price version id.</summary>
    public required Guid PriceVersionId { get; init; }
    /// <summary>The amount paisa.</summary>
    public required long AmountPaisa { get; init; }
    /// <summary>The actor id.</summary>
    public Guid? ActorId { get; init; }
}
