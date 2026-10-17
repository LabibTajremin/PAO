using PAO.Lib.Common;
using PAO.Lib.Events;

namespace PAO.Lib.Areas.Booking;

/// <summary>Names of the events the Booking area publishes.</summary>
public static class BookingEvents
{
    public const string BookingRequested = "booking.BookingRequested";
    public const string BookingAccepted = "booking.BookingAccepted";
    public const string BookingRejected = "booking.BookingRejected";
    public const string BookingTimedOut = "booking.BookingTimedOut";
    public const string ProviderOnTheWay = "booking.ProviderOnTheWay";
    public const string ProviderArrived = "booking.ProviderArrived";
    public const string BookingStarted = "booking.BookingStarted";
    public const string ExtraItemsProposed = "booking.ExtraItemsProposed";
    public const string ExtraItemsDecided = "booking.ExtraItemsDecided";
    public const string BookingCompleted = "booking.BookingCompleted";
    public const string BookingCancelled = "booking.BookingCancelled";
}

/// <summary>The fields every booking event carries.</summary>
public abstract record BookingEvent(string Name) : IDomainEvent
{
    public required Guid BookingId { get; init; }
    public required string Number { get; init; }
    public required Guid CustomerId { get; init; }
    public required Guid ProviderId { get; init; }
    public required Guid ServiceId { get; init; }
    public required string At { get; init; }
}

/// <summary>A customer requested a booking.</summary>
public sealed record BookingRequested() : BookingEvent(BookingEvents.BookingRequested)
{
    public required string AcceptDeadline { get; init; }
    public required bool Scheduled { get; init; }
    public required long TotalPaisa { get; init; }
}

/// <summary>The merchant accepted.</summary>
public sealed record BookingAccepted() : BookingEvent(BookingEvents.BookingAccepted);

/// <summary>The merchant rejected.</summary>
public sealed record BookingRejected() : BookingEvent(BookingEvents.BookingRejected)
{
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
    public required Guid ProposalId { get; init; }
    public required long AddedPaisa { get; init; }
    public required long NewTotalPaisa { get; init; }
}

/// <summary>The customer decided on extra items.</summary>
public sealed record ExtraItemsDecided() : BookingEvent(BookingEvents.ExtraItemsDecided)
{
    public required Guid ProposalId { get; init; }
    public required bool Approved { get; init; }
}

/// <summary>The job was completed.</summary>
public sealed record BookingCompleted() : BookingEvent(BookingEvents.BookingCompleted)
{
    public required long TotalPaisa { get; init; }
    public required string CustomerName { get; init; }
    public required string ProviderName { get; init; }
    public required Text ServiceName { get; init; }
}

/// <summary>A party cancelled.</summary>
public sealed record BookingCancelled() : BookingEvent(BookingEvents.BookingCancelled)
{
    public required string By { get; init; }
    public required string Reason { get; init; }
    public required bool AfterAcceptance { get; init; }
}
