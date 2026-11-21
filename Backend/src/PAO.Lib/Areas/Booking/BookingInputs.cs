namespace PAO.Lib.Areas.Booking;

/// <summary>One requested sub-service (`BookingItemInput`).</summary>
public sealed record BookingItemInput
{
    /// <summary>The sub-service.</summary>
    public Guid SubServiceId { get; init; }
    /// <summary>The quantity.</summary>
    public int Quantity { get; init; }
}

/// <summary>The `BookingCreate` body (C-06).</summary>
public sealed record BookingCreateInput
{
    /// <summary>The provider asked.</summary>
    public Guid ProviderId { get; init; }
    /// <summary>The service.</summary>
    public Guid ServiceId { get; init; }
    /// <summary>One to ten items.</summary>
    public IReadOnlyList<BookingItemInput> Items { get; init; } = [];
    /// <summary>`asap` or `scheduled`.</summary>
    public string Timing { get; init; } = string.Empty;
    /// <summary>The start of a scheduled job.</summary>
    public DateTimeOffset? ScheduledAt { get; init; }
    /// <summary>The saved address.</summary>
    public Guid AddressId { get; init; }
    /// <summary>The note; empty when missing.</summary>
    public string? Note { get; init; }
}

/// <summary>A reason with an optional note: `CustomerCancelInput`, `ProviderCancelInput` and `RejectInput`.</summary>
public sealed record ReasonInput
{
    /// <summary>The reason key.</summary>
    public string Reason { get; init; } = string.Empty;
    /// <summary>The note.</summary>
    public string? Note { get; init; }

    /// <summary>The reason as Go stored it: `reason: note`, or the reason alone.</summary>
    public string Stored => string.IsNullOrEmpty(Note) ? Reason : $"{Reason}: {Note}";
}

/// <summary>The `StartCode` body.</summary>
public sealed record StartCodeInput
{
    /// <summary>The 4-digit code.</summary>
    public string Code { get; init; } = string.Empty;
}

/// <summary>The `ExtrasInput` body.</summary>
public sealed record ExtrasInput
{
    /// <summary>One to ten catalog items of the booked service.</summary>
    public IReadOnlyList<BookingItemInput> Items { get; init; } = [];
}

/// <summary>The `ExtrasDecisionInput` body.</summary>
public sealed record ExtrasDecisionInput
{
    /// <summary>The pending proposal.</summary>
    public Guid ProposalId { get; init; }
    /// <summary>Whether the customer approves.</summary>
    public bool Approve { get; init; }
}

/// <summary>The `CompleteInput` body.</summary>
public sealed record CompleteInput
{
    /// <summary>Must be true (D4).</summary>
    public bool CashReceived { get; init; }
}

/// <summary>The query of `findNearbyProviders` (C10).</summary>
public sealed record NearbyInput
{
    /// <summary>The service.</summary>
    public Guid ServiceId { get; init; }
    /// <summary>The sub-service to price.</summary>
    public Guid SubServiceId { get; init; }
    /// <summary>Its quantity.</summary>
    public int Quantity { get; init; }
    /// <summary>A saved address to search around.</summary>
    public Guid? AddressId { get; init; }
    /// <summary>Or a point's latitude.</summary>
    public double? Lat { get; init; }
    /// <summary>And longitude.</summary>
    public double? Lng { get; init; }
    /// <summary>`distance` or `rating`.</summary>
    public string? Sort { get; init; }
    /// <summary>The page size.</summary>
    public int? Limit { get; init; }
}

/// <summary>The query of `listAdminBookings` (A-06); dates are Dhaka days.</summary>
public sealed record MonitorInput
{
    /// <summary>The status.</summary>
    public string? Status { get; init; }
    /// <summary>The service.</summary>
    public Guid? ServiceId { get; init; }
    /// <summary>The first day, YYYY-MM-DD.</summary>
    public string? From { get; init; }
    /// <summary>The last day, YYYY-MM-DD, included.</summary>
    public string? To { get; init; }
    /// <summary>The area.</summary>
    public string? Area { get; init; }
    /// <summary>The cursor.</summary>
    public string? Cursor { get; init; }
    /// <summary>The page size.</summary>
    public int? Limit { get; init; }
}
