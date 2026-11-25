using PAO.Lib.Areas.Catalog;
using PAO.Lib.Common;

namespace PAO.Lib.Areas.Booking;

/// <summary>The body of createSubscription.</summary>
public sealed record SubscriptionCreateInput
{
    /// <summary>The merchant.</summary>
    public Guid ProviderId { get; init; }
    /// <summary>The scheduled-delivery service.</summary>
    public Guid ServiceId { get; init; }
    /// <summary>The sub-services and quantities of one delivery.</summary>
    public IReadOnlyList<BookingItemInput> Items { get; init; } = [];
    /// <summary>The address.</summary>
    public Guid AddressId { get; init; }
    /// <summary>One of <see cref="DeliveryPattern"/>.</summary>
    public string Pattern { get; init; } = string.Empty;
    /// <summary>The days of the week for weekdays and weekly.</summary>
    public IReadOnlyList<int>? Weekdays { get; init; }
    /// <summary>The day of the month for monthly.</summary>
    public int? DayOfMonth { get; init; }
    /// <summary>One of the service's windows.</summary>
    public DeliveryWindow? Window { get; init; }
    /// <summary>The first date, YYYY-MM-DD.</summary>
    public string StartDate { get; init; } = string.Empty;
    /// <summary>The last date, YYYY-MM-DD, if any.</summary>
    public string? EndDate { get; init; }
    /// <summary>How many deliveries, instead of an end date.</summary>
    public int? Count { get; init; }
    /// <summary>A note.</summary>
    public string? Note { get; init; }
}

/// <summary>The body of changeDelivery: skip, bring back or change one date.</summary>
public sealed record DeliveryChangeInput
{
    /// <summary>True skips the date, false brings it back.</summary>
    public bool? Skip { get; init; }
    /// <summary>Other quantities for the date.</summary>
    public IReadOnlyList<BookingItemInput>? Items { get; init; }
}

/// <summary>One date of a subscription as the apps show it.</summary>
public sealed record DeliveryDateView
{
    /// <summary>The date, YYYY-MM-DD.</summary>
    public required string Date { get; init; }
    /// <summary>One of <see cref="DeliveryStatus"/>.</summary>
    public required string Status { get; init; }
    /// <summary>The quantities of the date.</summary>
    public required IReadOnlyList<BookingItemInput> Items { get; init; }
    /// <summary>The date's total in paisa.</summary>
    public required long Total { get; init; }
    /// <summary>The booking the date became.</summary>
    public Guid? BookingId { get; init; }
    /// <summary>Whether the cutoff has not passed.</summary>
    public required bool Changeable { get; init; }
}

/// <summary>A subscription as the customer, merchant or support sees it.</summary>
public sealed record SubscriptionView
{
    /// <summary>The id.</summary>
    public required Guid Id { get; init; }
    /// <summary>The number.</summary>
    public required string Number { get; init; }
    /// <summary>The status.</summary>
    public required string Status { get; init; }
    /// <summary>The service.</summary>
    public required Guid ServiceId { get; init; }
    /// <summary>The service name.</summary>
    public required Text ServiceName { get; init; }
    /// <summary>The merchant.</summary>
    public BookingPartyView? Provider { get; init; }
    /// <summary>The customer.</summary>
    public BookingPartyView? Customer { get; init; }
    /// <summary>The lines of one delivery.</summary>
    public required IReadOnlyList<BookingItemView> Items { get; init; }
    /// <summary>The total of one delivery.</summary>
    public required long Total { get; init; }
    /// <summary>What the quantity counts.</summary>
    public required string Unit { get; init; }
    /// <summary>The pattern.</summary>
    public required string Pattern { get; init; }
    /// <summary>The days of the week.</summary>
    public IReadOnlyList<int>? Weekdays { get; init; }
    /// <summary>The day of the month.</summary>
    public int? DayOfMonth { get; init; }
    /// <summary>The window.</summary>
    public required DeliveryWindow Window { get; init; }
    /// <summary>The first date.</summary>
    public required string StartDate { get; init; }
    /// <summary>The last date.</summary>
    public string? EndDate { get; init; }
    /// <summary>The count.</summary>
    public int? Count { get; init; }
    /// <summary>The address.</summary>
    public required BookingAddressView Address { get; init; }
    /// <summary>The note.</summary>
    public string? Note { get; init; }
    /// <summary>When it was ordered.</summary>
    public required string CreatedAt { get; init; }
    /// <summary>The next dates; only on detail reads.</summary>
    public IReadOnlyList<DeliveryDateView>? Upcoming { get; init; }
}

/// <summary>A list of subscriptions.</summary>
public sealed record SubscriptionListView(IReadOnlyList<SubscriptionView> Items);

/// <summary>One delivery in the merchant's daily list and calendar.</summary>
public sealed record ProviderDeliveryView
{
    /// <summary>The subscription.</summary>
    public required Guid SubscriptionId { get; init; }
    /// <summary>The subscription's number.</summary>
    public required string Number { get; init; }
    /// <summary>The date.</summary>
    public required string Date { get; init; }
    /// <summary>The window.</summary>
    public required DeliveryWindow Window { get; init; }
    /// <summary>The status.</summary>
    public required string Status { get; init; }
    /// <summary>The service name.</summary>
    public required Text ServiceName { get; init; }
    /// <summary>The quantities.</summary>
    public required IReadOnlyList<BookingItemInput> Items { get; init; }
    /// <summary>The total.</summary>
    public required long Total { get; init; }
    /// <summary>The address, exact for the merchant who accepted.</summary>
    public required BookingAddressView Address { get; init; }
    /// <summary>The customer's name.</summary>
    public string? CustomerName { get; init; }
    /// <summary>The booking the date became.</summary>
    public Guid? BookingId { get; init; }
}

/// <summary>A list of deliveries.</summary>
public sealed record ProviderDeliveryListView(IReadOnlyList<ProviderDeliveryView> Items);
