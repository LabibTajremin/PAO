using PAO.Lib.Common;

namespace PAO.Lib.Areas.Booking;

/// <summary>Booking states (PRD §5).</summary>
public static class BookingStatus
{
    /// <summary>The `"requested"` value.</summary>
    public const string Requested = "requested";
    /// <summary>The `"accepted"` value.</summary>
    public const string Accepted = "accepted";
    /// <summary>The `"on_the_way"` value.</summary>
    public const string OnTheWay = "on_the_way";
    /// <summary>The `"arrived"` value.</summary>
    public const string Arrived = "arrived";
    /// <summary>The `"in_progress"` value.</summary>
    public const string InProgress = "in_progress";
    /// <summary>The `"completed"` value.</summary>
    public const string Completed = "completed";
    /// <summary>The `"rejected"` value.</summary>
    public const string Rejected = "rejected";
    /// <summary>The `"timed_out"` value.</summary>
    public const string TimedOut = "timed_out";
    /// <summary>The `"cancelled"` value.</summary>
    public const string Cancelled = "cancelled";
}

/// <summary>A booking with its parties and snapshots.</summary>
public sealed record BookingDetails
{
    /// <summary>The id.</summary>
    public required Guid Id { get; init; }
    /// <summary>The number.</summary>
    public required string Number { get; init; }
    /// <summary>The status.</summary>
    public required string Status { get; init; }
    /// <summary>The customer id.</summary>
    public required Guid CustomerId { get; init; }
    /// <summary>The provider id.</summary>
    public required Guid ProviderId { get; init; }
    /// <summary>The service id.</summary>
    public required Guid ServiceId { get; init; }
    /// <summary>The service name.</summary>
    public required Text ServiceName { get; init; }
    /// <summary>The customer name.</summary>
    public required string CustomerName { get; init; }
    /// <summary>The provider name.</summary>
    public required string ProviderName { get; init; }
    /// <summary>The area.</summary>
    public required string Area { get; init; }
    /// <summary>The total paisa.</summary>
    public required long TotalPaisa { get; init; }
    /// <summary>The created at.</summary>
    public required DateTimeOffset CreatedAt { get; init; }
    /// <summary>The completed at.</summary>
    public DateTimeOffset? CompletedAt { get; init; }
}

/// <summary>A line of a party's recent bookings on admin pages.</summary>
public sealed record BookingSummary
{
    /// <summary>The id.</summary>
    public required Guid Id { get; init; }
    /// <summary>The number.</summary>
    public required string Number { get; init; }
    /// <summary>The status.</summary>
    public required string Status { get; init; }
    /// <summary>The service name.</summary>
    public required Text ServiceName { get; init; }
    /// <summary>The total paisa.</summary>
    public required long TotalPaisa { get; init; }
    /// <summary>The created at.</summary>
    public required DateTimeOffset CreatedAt { get; init; }
}

/// <summary>Completed jobs and recent merchant cancellations (D13).</summary>
public sealed record MerchantStats
{
    /// <summary>The completed jobs.</summary>
    public required int CompletedJobs { get; init; }
    /// <summary>The cancellations 30d.</summary>
    public required int Cancellations30d { get; init; }
}

/// <summary>The Booking area's error reasons.</summary>
public static class BookingErrors
{
    /// <summary>The `"booking.not_found"` value.</summary>
    public const string NotFound = "booking.not_found";
}
