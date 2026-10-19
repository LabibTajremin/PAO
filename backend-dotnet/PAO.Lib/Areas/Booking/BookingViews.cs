using System.Text.Json.Serialization;
using PAO.Lib.Common;

namespace PAO.Lib.Areas.Booking;

/// <summary>The spec's `BookingItem`.</summary>
public sealed record BookingItemView
{
    /// <summary>The sub-service.</summary>
    public required Guid SubServiceId { get; init; }
    /// <summary>The price version.</summary>
    public required Guid PriceVersionId { get; init; }
    /// <summary>The name.</summary>
    public required Text Name { get; init; }
    /// <summary>The unit.</summary>
    public required string Unit { get; init; }
    /// <summary>The quantity.</summary>
    public required int Quantity { get; init; }
    /// <summary>The unit price.</summary>
    public required long UnitPrice { get; init; }
    /// <summary>The line total.</summary>
    public required long Total { get; init; }
    /// <summary>Whether it was added during the job.</summary>
    public required bool Extra { get; init; }
}

/// <summary>The spec's `BookingParty`; the phone only once it is shared.</summary>
public sealed record BookingPartyView
{
    /// <summary>The id.</summary>
    public required Guid Id { get; init; }
    /// <summary>The name.</summary>
    public required string Name { get; init; }
    /// <summary>The phone.</summary>
    [JsonIgnore(Condition = JsonIgnoreCondition.WhenWritingNull)]
    public string? Phone { get; init; }
}

/// <summary>The spec's `BookingAddress`; the exact lines only once they are shared.</summary>
public sealed record BookingAddressView
{
    /// <summary>The area.</summary>
    public required string Area { get; init; }
    /// <summary>The first line.</summary>
    [JsonIgnore(Condition = JsonIgnoreCondition.WhenWritingNull)]
    public string? Line1 { get; init; }
    /// <summary>The second line.</summary>
    [JsonIgnore(Condition = JsonIgnoreCondition.WhenWritingNull)]
    public string? Line2 { get; init; }
    /// <summary>The point.</summary>
    [JsonIgnore(Condition = JsonIgnoreCondition.WhenWritingNull)]
    public GeoPoint? Location { get; init; }
}

/// <summary>The spec's `ExtrasProposal`.</summary>
public sealed record ExtrasProposalView
{
    /// <summary>The id.</summary>
    public required Guid Id { get; init; }
    /// <summary>The items.</summary>
    public required IReadOnlyList<BookingItemView> Items { get; init; }
    /// <summary>What they add.</summary>
    public required long AddedTotal { get; init; }
    /// <summary>The bill with them.</summary>
    public required long NewTotal { get; init; }
    /// <summary>The status.</summary>
    public required string Status { get; init; }
    /// <summary>When proposed.</summary>
    public required string ProposedAt { get; init; }
}

/// <summary>The spec's `TimelineEntry`.</summary>
public sealed record TimelineEntryView
{
    /// <summary>The status.</summary>
    public required string Status { get; init; }
    /// <summary>When.</summary>
    public required string At { get; init; }
    /// <summary>Who.</summary>
    public required string Actor { get; init; }
    /// <summary>Why, when given.</summary>
    [JsonIgnore(Condition = JsonIgnoreCondition.WhenWritingNull)]
    public string? Reason { get; init; }
}

/// <summary>The spec's `Booking` for one side, field for field what NestJS answered.</summary>
public sealed record BookingView
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
    /// <summary>The service model.</summary>
    public required string ServiceModel { get; init; }
    /// <summary>The provider.</summary>
    public required BookingPartyView Provider { get; init; }
    /// <summary>The customer.</summary>
    public required BookingPartyView Customer { get; init; }
    /// <summary>The bill's lines.</summary>
    public required IReadOnlyList<BookingItemView> Items { get; init; }
    /// <summary>The bill.</summary>
    public required long Total { get; init; }
    /// <summary>`asap` or `scheduled`.</summary>
    public required string Timing { get; init; }
    /// <summary>The scheduled start.</summary>
    [JsonIgnore(Condition = JsonIgnoreCondition.WhenWritingNull)]
    public string? ScheduledAt { get; init; }
    /// <summary>The end of a duration hire.</summary>
    [JsonIgnore(Condition = JsonIgnoreCondition.WhenWritingNull)]
    public string? EndsAt { get; init; }
    /// <summary>The address.</summary>
    public required BookingAddressView Address { get; init; }
    /// <summary>The note.</summary>
    public required string Note { get; init; }
    /// <summary>The accept deadline.</summary>
    public required string AcceptDeadline { get; init; }
    /// <summary>The proposal waiting for the customer.</summary>
    [JsonIgnore(Condition = JsonIgnoreCondition.WhenWritingNull)]
    public ExtrasProposalView? PendingExtras { get; init; }
    /// <summary>Whether the caller may still cancel.</summary>
    public required bool Cancellable { get; init; }
    /// <summary>`cash_on_delivery`, the only method of the first release (ADR-0035 §1).</summary>
    public required string PaymentMethod { get; init; }
    /// <summary>Whether the cash was confirmed.</summary>
    public required bool CashReceived { get; init; }
    /// <summary>When requested.</summary>
    public required string CreatedAt { get; init; }
    /// <summary>The timeline.</summary>
    public required IReadOnlyList<TimelineEntryView> Timeline { get; init; }
    /// <summary>Whether the caller already reviewed it (detail views only).</summary>
    [JsonIgnore(Condition = JsonIgnoreCondition.WhenWritingNull)]
    public bool? ReviewedByMe { get; init; }
}

/// <summary>The spec's `Receipt`.</summary>
public sealed record ReceiptView
{
    /// <summary>The booking.</summary>
    public required Guid BookingId { get; init; }
    /// <summary>The number.</summary>
    public required string Number { get; init; }
    /// <summary>When completed.</summary>
    public required string CompletedAt { get; init; }
    /// <summary>The service name.</summary>
    public required Text ServiceName { get; init; }
    /// <summary>The provider name.</summary>
    public required string ProviderName { get; init; }
    /// <summary>The customer name.</summary>
    public required string CustomerName { get; init; }
    /// <summary>The area.</summary>
    public required string Area { get; init; }
    /// <summary>The lines.</summary>
    public required IReadOnlyList<BookingItemView> Items { get; init; }
    /// <summary>The bill.</summary>
    public required long Total { get; init; }
    /// <summary>`cash_on_delivery`, the only method of the first release (ADR-0035 §1).</summary>
    public required string PaymentMethod { get; init; }
}

/// <summary>The spec's `BookingSummary` as a list row.</summary>
public sealed record BookingListItemView
{
    /// <summary>The id.</summary>
    public required Guid Id { get; init; }
    /// <summary>The number.</summary>
    public required string Number { get; init; }
    /// <summary>The status.</summary>
    public required string Status { get; init; }
    /// <summary>The service name.</summary>
    public required Text ServiceName { get; init; }
    /// <summary>The other side's name.</summary>
    public required string CounterpartName { get; init; }
    /// <summary>The timing.</summary>
    public required string Timing { get; init; }
    /// <summary>The scheduled start.</summary>
    [JsonIgnore(Condition = JsonIgnoreCondition.WhenWritingNull)]
    public string? ScheduledAt { get; init; }
    /// <summary>The bill.</summary>
    public required long Total { get; init; }
    /// <summary>When requested.</summary>
    public required string CreatedAt { get; init; }
}

/// <summary>The spec's `BookingList`.</summary>
public sealed record BookingListView
{
    /// <summary>The rows.</summary>
    public required IReadOnlyList<BookingListItemView> Items { get; init; }
    /// <summary>The cursor of the next page.</summary>
    [JsonIgnore(Condition = JsonIgnoreCondition.WhenWritingNull)]
    public string? NextCursor { get; init; }
}

/// <summary>The start code the customer reads out.</summary>
public sealed record StartCodeView
{
    /// <summary>The code.</summary>
    public required string Code { get; init; }
}
