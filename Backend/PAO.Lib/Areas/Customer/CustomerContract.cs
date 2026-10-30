using PAO.Lib.Common;
using PAO.Lib.Events;

namespace PAO.Lib.Areas.Customer;

/// <summary>A customer profile.</summary>
public sealed record CustomerProfile
{
    /// <summary>The id.</summary>
    public required Guid Id { get; init; }
    /// <summary>The name.</summary>
    public required string Name { get; init; }
    /// <summary>The photo media id.</summary>
    public Guid? PhotoMediaId { get; init; }
    /// <summary>The language.</summary>
    public required string Language { get; init; }
}

/// <summary>A saved address with its exact location; revealed to a provider only after acceptance (PRD §11).</summary>
public sealed record CustomerAddress
{
    /// <summary>The id.</summary>
    public required Guid Id { get; init; }
    /// <summary>The customer id.</summary>
    public required Guid CustomerId { get; init; }
    /// <summary>The label.</summary>
    public required string Label { get; init; }
    /// <summary>The line 1.</summary>
    public required string Line1 { get; init; }
    /// <summary>The line 2.</summary>
    public required string Line2 { get; init; }
    /// <summary>The area.</summary>
    public required string Area { get; init; }
    /// <summary>The location.</summary>
    public required GeoPoint Location { get; init; }
}

/// <summary>Filters for the admin customer list (A-05), newest first.</summary>
public sealed record CustomerQuery
{
    /// <summary>The id.</summary>
    public Guid? Id { get; init; }
    /// <summary>The text.</summary>
    public required string Text { get; init; }
    /// <summary>The status.</summary>
    public required string Status { get; init; }
    /// <summary>The after at.</summary>
    public DateTimeOffset? AfterAt { get; init; }
    /// <summary>The after id.</summary>
    public Guid? AfterId { get; init; }
    /// <summary>The limit.</summary>
    public required int Limit { get; init; }
}

/// <summary>A row of the admin customer list.</summary>
public sealed record CustomerRecord
{
    /// <summary>The id.</summary>
    public required Guid Id { get; init; }
    /// <summary>The name.</summary>
    public required string Name { get; init; }
    /// <summary>The phone.</summary>
    public required string Phone { get; init; }
    /// <summary>The status.</summary>
    public required string Status { get; init; }
    /// <summary>The bookings.</summary>
    public required int Bookings { get; init; }
    /// <summary>The created at.</summary>
    public required DateTimeOffset CreatedAt { get; init; }
}

/// <summary>The Customer area's error reasons.</summary>
public static class CustomerErrors
{
    /// <summary>The `"customer.not_found"` value.</summary>
    public const string NotFound = "customer.not_found";
    /// <summary>The `"customer.address_not_found"` value.</summary>
    public const string AddressNotFound = "customer.address_not_found";
}

/// <summary>Names of the events the Customer area publishes.</summary>
public static class CustomerEvents
{
    /// <summary>The `"customer.CustomerProfileSaved"` value.</summary>
    public const string CustomerProfileSaved = "customer.CustomerProfileSaved";
}

/// <summary>A customer created or renamed their profile.</summary>
public sealed record CustomerProfileSaved : IDomainEvent
{
    /// <summary>The name.</summary>
    public string Name { get; } = CustomerEvents.CustomerProfileSaved;
    /// <summary>The customer id.</summary>
    public required Guid CustomerId { get; init; }
    /// <summary>The customer name.</summary>
    public required string CustomerName { get; init; }
}
