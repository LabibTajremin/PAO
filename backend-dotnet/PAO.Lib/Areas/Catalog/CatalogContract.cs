using PAO.Lib.Common;
using PAO.Lib.Events;

namespace PAO.Lib.Areas.Catalog;

/// <summary>How a service is sold (PRD §4).</summary>
public static class ServiceModel
{
    public const string OnDemand = "on_demand";
    public const string DurationHire = "duration_hire";
    public const string Listing = "listing";
    public const string PartnerReferral = "partner_referral";
}

/// <summary>What a price is per.</summary>
public static class PriceUnit
{
    public const string Job = "job";
    public const string Unit = "unit";
    public const string Hour = "hour";
    public const string Day = "day";
}

/// <summary>A service with its booking rules.</summary>
public sealed record CatalogService
{
    public required Guid Id { get; init; }
    public required Guid CategoryId { get; init; }
    public required Text Name { get; init; }
    public required string Model { get; init; }
    public required int RequiredLevel { get; init; }
    public required int SearchRadiusM { get; init; }
    public required bool WomenProvidersOnly { get; init; }
    public required bool RequiresLevel2 { get; init; }
    public required IReadOnlyList<Text> Level2Checklist { get; init; }
    public required bool Published { get; init; }
}

/// <summary>The current price of a sub-service, copied into bookings (PRD §4).</summary>
public sealed record PriceSnapshot
{
    public required Guid SubServiceId { get; init; }
    public required Guid ServiceId { get; init; }
    public required Guid PriceVersionId { get; init; }
    public required Text Name { get; init; }
    public required string Unit { get; init; }
    public required long AmountPaisa { get; init; }
    public required int MaxQuantity { get; init; }
    public required bool Published { get; init; }
}

/// <summary>The Catalog area's error reasons.</summary>
public static class CatalogErrors
{
    public const string ServiceNotFound = "catalog.service_not_found";
    public const string SubServiceNotFound = "catalog.sub_service_not_found";
}

/// <summary>Names of the events the Catalog area publishes.</summary>
public static class CatalogEvents
{
    public const string CatalogChanged = "catalog.CatalogChanged";
    public const string PriceChanged = "catalog.PriceChanged";
}

/// <summary>The published catalog changed; caches keyed by version are stale.</summary>
public sealed record CatalogChanged : IDomainEvent
{
    public string Name { get; } = CatalogEvents.CatalogChanged;
    public required long Version { get; init; }
}

/// <summary>A sub-service got a new price version.</summary>
public sealed record PriceChanged : IDomainEvent
{
    public string Name { get; } = CatalogEvents.PriceChanged;
    public required Guid SubServiceId { get; init; }
    public required Guid PriceVersionId { get; init; }
    public required long AmountPaisa { get; init; }
    public Guid? ActorId { get; init; }
}
