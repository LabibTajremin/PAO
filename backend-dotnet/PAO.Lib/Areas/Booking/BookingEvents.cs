using PAO.Lib.Common;
using PAO.Lib.Events;

namespace PAO.Lib.Areas.Booking;

/// <summary>Names of the events the Booking area publishes.</summary>
public static class BookingEvents
{
    /// <summary>The `"booking.BookingRequested"` value.</summary>
    public const string BookingRequested = "booking.BookingRequested";
    /// <summary>The `"booking.BookingAccepted"` value.</summary>
    public const string BookingAccepted = "booking.BookingAccepted";
    /// <summary>The `"booking.BookingRejected"` value.</summary>
    public const string BookingRejected = "booking.BookingRejected";
    /// <summary>The `"booking.BookingTimedOut"` value.</summary>
    public const string BookingTimedOut = "booking.BookingTimedOut";
    /// <summary>The `"booking.ProviderOnTheWay"` value.</summary>
    public const string ProviderOnTheWay = "booking.ProviderOnTheWay";
    /// <summary>The `"booking.ProviderArrived"` value.</summary>
    public const string ProviderArrived = "booking.ProviderArrived";
    /// <summary>The `"booking.BookingStarted"` value.</summary>
    public const string BookingStarted = "booking.BookingStarted";
    /// <summary>The `"booking.ExtraItemsProposed"` value.</summary>
    public const string ExtraItemsProposed = "booking.ExtraItemsProposed";
    /// <summary>The `"booking.ExtraItemsDecided"` value.</summary>
    public const string ExtraItemsDecided = "booking.ExtraItemsDecided";
    /// <summary>The `"booking.BookingCompleted"` value.</summary>
    public const string BookingCompleted = "booking.BookingCompleted";
    /// <summary>The `"booking.BookingCancelled"` value.</summary>
    public const string BookingCancelled = "booking.BookingCancelled";
}

/// <summary>The fields every booking event carries.</summary>
public abstract record BookingEvent(string Name) : IDomainEvent
{
    /// <summary>The booking id.</summary>
    public required Guid BookingId { get; init; }
    /// <summary>The number.</summary>
    public required string Number { get; init; }
    /// <summary>The customer id.</summary>
    public required Guid CustomerId { get; init; }
    /// <summary>The provider id.</summary>
    public required Guid ProviderId { get; init; }
    /// <summary>The service id.</summary>
    public required Guid ServiceId { get; init; }
    /// <summary>The at.</summary>
    public required string At { get; init; }
}

/// <summary>A customer requested a booking.</summary>
public sealed record BookingRequested() : BookingEvent(BookingEvents.BookingRequested)
{
    /// <summary>The accept deadline.</summary>
    public required string AcceptDeadline { get; init; }
    /// <summary>Whether scheduled.</summary>
    public required bool Scheduled { get; init; }
    /// <summary>The total paisa.</summary>
    public required long TotalPaisa { get; init; }
}

/// <summary>The merchant accepted.</summary>
public sealed record BookingAccepted() : BookingEvent(BookingEvents.BookingAccepted);

/// <summary>The merchant rejected.</summary>
public sealed record BookingRejected() : BookingEvent(BookingEvents.BookingRejected)
{
    /// <summary>The reason.</summary>
    public required string Reason { get; init; }
}

/// <summary>Nobody accepted in time.</summary>
public sealed record BookingTimedOut() : BookingEvent(BookingEvents.BookingTimedOut);

/// <summary>The merchant set off.</summary>
public sealed record ProviderOnTheWay() : BookingEvent(BookingEvents.ProviderOnTheWay);

/// <summary>The merchant arrived.</summary>
public sealed record ProviderArrived() : BookingEvent(BookingEvents.ProviderArrived);

/// <summary>The start code was entered.</summary>
public sealed record BookingStarted() : BookingEvent(BookingEvents.BookingStarted);

/// <summary>The merchant proposed extra items.</summary>
public sealed record ExtraItemsProposed() : BookingEvent(BookingEvents.ExtraItemsProposed)
{
    /// <summary>The proposal id.</summary>
    public required Guid ProposalId { get; init; }
    /// <summary>The added paisa.</summary>
    public required long AddedPaisa { get; init; }
    /// <summary>The new total paisa.</summary>
    public required long NewTotalPaisa { get; init; }
}

/// <summary>The customer decided on extra items.</summary>
public sealed record ExtraItemsDecided() : BookingEvent(BookingEvents.ExtraItemsDecided)
{
    /// <summary>The proposal id.</summary>
    public required Guid ProposalId { get; init; }
    /// <summary>Whether approved.</summary>
    public required bool Approved { get; init; }
}

/// <summary>The job was completed.</summary>
public sealed record BookingCompleted() : BookingEvent(BookingEvents.BookingCompleted)
{
    /// <summary>The total paisa.</summary>
    public required long TotalPaisa { get; init; }
    /// <summary>The customer name.</summary>
    public required string CustomerName { get; init; }
    /// <summary>The provider name.</summary>
    public required string ProviderName { get; init; }
    /// <summary>The service name.</summary>
    public required Text ServiceName { get; init; }
}

/// <summary>A party cancelled.</summary>
public sealed record BookingCancelled() : BookingEvent(BookingEvents.BookingCancelled)
{
    /// <summary>The by.</summary>
    public required string By { get; init; }
    /// <summary>The reason.</summary>
    public required string Reason { get; init; }
    /// <summary>Whether after acceptance.</summary>
    public required bool AfterAcceptance { get; init; }
}
