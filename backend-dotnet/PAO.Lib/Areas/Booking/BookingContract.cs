using PAO.Lib.Common;

namespace PAO.Lib.Areas.Booking;

/// <summary>Booking states (PRD §5).</summary>
public static class BookingStatus
{
    public const string Requested = "requested";
    public const string Accepted = "accepted";
    public const string OnTheWay = "on_the_way";
    public const string Arrived = "arrived";
    public const string InProgress = "in_progress";
    public const string Completed = "completed";
    public const string Rejected = "rejected";
    public const string TimedOut = "timed_out";
    public const string Cancelled = "cancelled";
}

/// <summary>A booking with its parties and snapshots.</summary>
public sealed record BookingDetails
{
    public required Guid Id { get; init; }
    public required string Number { get; init; }
    public required string Status { get; init; }
    public required Guid CustomerId { get; init; }
    public required Guid ProviderId { get; init; }
    public required Guid ServiceId { get; init; }
    public required Text ServiceName { get; init; }
    public required string CustomerName { get; init; }
    public required string ProviderName { get; init; }
    public required string Area { get; init; }
    public required long TotalPaisa { get; init; }
    public required DateTimeOffset CreatedAt { get; init; }
    public DateTimeOffset? CompletedAt { get; init; }
}

/// <summary>A line of a party's recent bookings on admin pages.</summary>
public sealed record BookingSummary
{
    public required Guid Id { get; init; }
    public required string Number { get; init; }
    public required string Status { get; init; }
    public required Text ServiceName { get; init; }
    public required long TotalPaisa { get; init; }
    public required DateTimeOffset CreatedAt { get; init; }
}

/// <summary>Completed jobs and recent merchant cancellations (D13).</summary>
public sealed record MerchantStats
{
    public required int CompletedJobs { get; init; }
    public required int Cancellations30d { get; init; }
}

/// <summary>The Booking area's error reasons.</summary>
public static class BookingErrors
{
    public const string NotFound = "booking.not_found";
}
