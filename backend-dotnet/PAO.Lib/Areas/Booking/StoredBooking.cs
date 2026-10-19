using PAO.Lib.Common;

namespace PAO.Lib.Areas.Booking;

/// <summary>The aggregate the state machine moves, loaded with its lines, proposals and timeline.</summary>
public sealed class StoredBooking
{
    /// <summary>The id.</summary>
    public required Guid Id { get; init; }
    /// <summary>The sequence number; 0 until stored.</summary>
    public long Number { get; set; }
    /// <summary>The customer snapshot.</summary>
    public required BookingParty Customer { get; init; }
    /// <summary>The provider snapshot.</summary>
    public required BookingParty Provider { get; init; }
    /// <summary>The service.</summary>
    public required Guid ServiceId { get; init; }
    /// <summary>The service name.</summary>
    public required Text ServiceName { get; init; }
    /// <summary>The service model.</summary>
    public required string ServiceModel { get; init; }
    /// <summary>The address snapshot.</summary>
    public required AddressSnapshot Address { get; init; }
    /// <summary>The customer's note.</summary>
    public required string Note { get; init; }
    /// <summary>The state.</summary>
    public required string Status { get; set; }
    /// <summary>Whether it is for a later time.</summary>
    public required bool Scheduled { get; init; }
    /// <summary>The scheduled start.</summary>
    public DateTimeOffset? ScheduledAt { get; init; }
    /// <summary>The end of a duration hire.</summary>
    public DateTimeOffset? EndsAt { get; init; }
    /// <summary>When the provider's time to answer runs out.</summary>
    public required DateTimeOffset AcceptDeadline { get; init; }
    /// <summary>The bill.</summary>
    public long TotalPaisa { get; set; }
    /// <summary>The start code; empty until accepted.</summary>
    public string StartCode { get; set; } = string.Empty;
    /// <summary>Wrong codes since the last lockout.</summary>
    public int CodeAttempts { get; set; }
    /// <summary>Until when code entry is locked.</summary>
    public DateTimeOffset? CodeLockedUntil { get; set; }
    /// <summary>Whether the provider confirmed the cash.</summary>
    public bool CashReceived { get; set; }
    /// <summary>The creating request's key.</summary>
    public required string IdempotencyKey { get; init; }
    /// <summary>Why it was cancelled.</summary>
    public string CancelReason { get; set; } = string.Empty;
    /// <summary>Who cancelled.</summary>
    public string CancelledBy { get; set; } = string.Empty;
    /// <summary>Why the provider rejected.</summary>
    public string RejectReason { get; set; } = string.Empty;
    /// <summary>When requested.</summary>
    public required DateTimeOffset CreatedAt { get; init; }
    /// <summary>When accepted.</summary>
    public DateTimeOffset? AcceptedAt { get; set; }
    /// <summary>When started.</summary>
    public DateTimeOffset? StartedAt { get; set; }
    /// <summary>When completed.</summary>
    public DateTimeOffset? CompletedAt { get; set; }
    /// <summary>When cancelled.</summary>
    public DateTimeOffset? CancelledAt { get; set; }
    /// <summary>The bill's lines, approved extras included.</summary>
    public List<BookingLine> Lines { get; set; } = [];
    /// <summary>Every extras proposal, oldest first.</summary>
    public List<ExtrasProposal> Proposals { get; init; } = [];
    /// <summary>The timeline, oldest first.</summary>
    public List<TimelineEntry> Timeline { get; init; } = [];
    /// <summary>The provider's other active jobs, counted under the provider lock.</summary>
    public int ProviderActiveJobs { get; set; }
    /// <summary>Timeline entries added since loading.</summary>
    public List<TimelineEntry> NewEvents { get; init; } = [];

    /// <summary>The number as people read it, e.g. PAO-104233.</summary>
    public string DisplayNumber => BookingNumbers.Format(Number);

    /// <summary>The proposal waiting for the customer, if any.</summary>
    public ExtrasProposal? Pending => Proposals.Find(p => p.Status == "pending");
}

/// <summary>Booking numbers as people read them.</summary>
public static class BookingNumbers
{
    /// <summary>`PAO-{n}`.</summary>
    public static string Format(long n) => $"PAO-{n.ToString(System.Globalization.CultureInfo.InvariantCulture)}";
}
