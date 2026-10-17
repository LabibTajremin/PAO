using PAO.Lib.Common;
using PAO.Lib.Events;

namespace PAO.Lib.Areas.Customer;

/// <summary>A customer profile.</summary>
public sealed record CustomerProfile
{
    public required Guid Id { get; init; }
    public required string Name { get; init; }
    public Guid? PhotoMediaId { get; init; }
    public required string Language { get; init; }
}

/// <summary>A saved address with its exact location; revealed to a provider only after acceptance (PRD §11).</summary>
public sealed record CustomerAddress
{
    public required Guid Id { get; init; }
    public required Guid CustomerId { get; init; }
    public required string Label { get; init; }
    public required string Line1 { get; init; }
    public required string Line2 { get; init; }
    public required string Area { get; init; }
    public required GeoPoint Location { get; init; }
}

/// <summary>Filters for the admin customer list (A-05), newest first.</summary>
public sealed record CustomerQuery
{
    public Guid? Id { get; init; }
    public required string Text { get; init; }
    public required string Status { get; init; }
    public DateTimeOffset? AfterAt { get; init; }
    public Guid? AfterId { get; init; }
    public required int Limit { get; init; }
}

/// <summary>A row of the admin customer list.</summary>
public sealed record CustomerRecord
{
    public required Guid Id { get; init; }
    public required string Name { get; init; }
    public required string Phone { get; init; }
    public required string Status { get; init; }
    public required int Bookings { get; init; }
    public required DateTimeOffset CreatedAt { get; init; }
}

/// <summary>The Customer area's error reasons.</summary>
public static class CustomerErrors
{
    public const string NotFound = "customer.not_found";
    public const string AddressNotFound = "customer.address_not_found";
}

/// <summary>Names of the events the Customer area publishes.</summary>
public static class CustomerEvents
{
    public const string CustomerProfileSaved = "customer.CustomerProfileSaved";
}

/// <summary>A customer created or renamed their profile.</summary>
public sealed record CustomerProfileSaved : IDomainEvent
{
    public string Name { get; } = CustomerEvents.CustomerProfileSaved;
    public required Guid CustomerId { get; init; }
    public required string CustomerName { get; init; }
}
