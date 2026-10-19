using PAO.Lib.Common;
using PAO.Lib.Mediator;

namespace PAO.Lib.Areas.Booking;

/// <summary>Why a booking rule refused something; `NotFound` equals <see cref="BookingErrors.NotFound"/>.</summary>
public static class BookingReasons
{
    /// <summary>The `"booking.not_found"` value.</summary>
    public const string NotFound = BookingErrors.NotFound;
    /// <summary>The `"booking.invalid"` value.</summary>
    public const string Invalid = "booking.invalid";
    /// <summary>The `"booking.invalid_transition"` value.</summary>
    public const string InvalidTransition = "booking.invalid_transition";
    /// <summary>The `"booking.deadline_passed"` value.</summary>
    public const string DeadlinePassed = "booking.deadline_passed";
    /// <summary>The `"booking.active_job"` value.</summary>
    public const string ActiveJob = "booking.active_job";
    /// <summary>The `"booking.code_wrong"` value.</summary>
    public const string CodeWrong = "booking.code_wrong";
    /// <summary>The `"booking.code_locked"` value.</summary>
    public const string CodeLocked = "booking.code_locked";
    /// <summary>The `"booking.cash_not_confirmed"` value.</summary>
    public const string CashNotConfirmed = "booking.cash_not_confirmed";
    /// <summary>The `"booking.extras_pending"` value.</summary>
    public const string ExtrasPending = "booking.extras_pending";
    /// <summary>The `"booking.no_proposal"` value.</summary>
    public const string NoProposal = "booking.no_proposal";
    /// <summary>The `"booking.not_bookable"` value.</summary>
    public const string NotBookable = "booking.not_bookable";
    /// <summary>The `"booking.duplicate_request"` value.</summary>
    public const string DuplicateRequest = "booking.duplicate_request";
    /// <summary>The `"booking.cancel_not_allowed"` value.</summary>
    public const string CancelNotAllowed = "booking.cancel_not_allowed";
    /// <summary>The `"booking.outside_area"` value.</summary>
    public const string OutsideArea = "booking.outside_area";
    /// <summary>The `"booking.profile_required"` value.</summary>
    public const string ProfileRequired = "booking.profile_required";

    /// <summary>Every reason, for the error-map test.</summary>
    public static readonly IReadOnlyList<string> All =
    [
        NotFound, Invalid, InvalidTransition, DeadlinePassed, ActiveJob, CodeWrong, CodeLocked, CashNotConfirmed,
        ExtrasPending, NoProposal, NotBookable, DuplicateRequest, CancelNotAllowed, OutsideArea, ProfileRequired,
    ];
}

/// <summary>Who moves a booking.</summary>
public static class BookingActor
{
    /// <summary>The `"customer"` value.</summary>
    public const string Customer = "customer";
    /// <summary>The `"provider"` value.</summary>
    public const string Provider = "provider";
    /// <summary>The `"system"` value.</summary>
    public const string System = "system";
}

/// <summary>A priced item copied from the catalog (PRD §9.3 rule 4); lines never change once stored.</summary>
public sealed record BookingLine
{
    /// <summary>The id.</summary>
    public required Guid Id { get; init; }
    /// <summary>The sub-service.</summary>
    public required Guid SubServiceId { get; init; }
    /// <summary>The price version copied.</summary>
    public required Guid PriceVersionId { get; init; }
    /// <summary>The name.</summary>
    public required Text Name { get; init; }
    /// <summary>The price unit.</summary>
    public required string Unit { get; init; }
    /// <summary>The quantity.</summary>
    public required int Quantity { get; init; }
    /// <summary>The unit price.</summary>
    public required long UnitPaisa { get; init; }
    /// <summary>The line total.</summary>
    public required long TotalPaisa { get; init; }
    /// <summary>Whether it was approved as an extra.</summary>
    public bool Extra { get; init; }
    /// <summary>The proposal it came with.</summary>
    public Guid? ProposalId { get; init; }
    /// <summary>The order on the bill.</summary>
    public int Position { get; init; }
}

/// <summary>A set of extra items waiting for, or answered by, the customer.</summary>
public sealed class ExtrasProposal
{
    /// <summary>The id.</summary>
    public required Guid Id { get; init; }
    /// <summary>`pending`, `approved` or `declined`.</summary>
    public required string Status { get; set; }
    /// <summary>What the items add.</summary>
    public long AddedPaisa { get; set; }
    /// <summary>When proposed.</summary>
    public required DateTimeOffset ProposedAt { get; init; }
    /// <summary>When answered.</summary>
    public DateTimeOffset? DecidedAt { get; set; }
    /// <summary>The items.</summary>
    public required List<BookingLine> Lines { get; init; }
}

/// <summary>One timeline entry.</summary>
public sealed record TimelineEntry(Guid Id, string Status, string Actor, string Reason, DateTimeOffset At);

/// <summary>A snapshot of one side of the booking.</summary>
public sealed record BookingParty(Guid Id, string Name, string Phone);

/// <summary>The service address snapshot.</summary>
public sealed record AddressSnapshot(Guid Id, string Area, string Line1, string Line2, GeoPoint Location);

/// <summary>A keyset position over (time, id); `Limit` includes the look-ahead row.</summary>
public sealed record BookingPage(DateTimeOffset? At, Guid? Id, int Limit);

/// <summary>Narrows the admin bookings monitor; `From` and `Until` bound created_at.</summary>
public sealed record MonitorFilter(string? Status, Guid? ServiceId, DateTimeOffset? From, DateTimeOffset? Until, string Area);

/// <summary>A list row.</summary>
public sealed record BookingRow
{
    /// <summary>The id.</summary>
    public required Guid Id { get; init; }
    /// <summary>The number.</summary>
    public required long Number { get; init; }
    /// <summary>The status.</summary>
    public required string Status { get; init; }
    /// <summary>The service name.</summary>
    public required Text ServiceName { get; init; }
    /// <summary>The customer name.</summary>
    public required string CustomerName { get; init; }
    /// <summary>The provider name.</summary>
    public required string ProviderName { get; init; }
    /// <summary>Whether scheduled.</summary>
    public required bool Scheduled { get; init; }
    /// <summary>The scheduled start.</summary>
    public DateTimeOffset? ScheduledAt { get; init; }
    /// <summary>The total.</summary>
    public required long TotalPaisa { get; init; }
    /// <summary>When requested.</summary>
    public required DateTimeOffset CreatedAt { get; init; }
}

/// <summary>One Dhaka calendar day of earnings.</summary>
public sealed record EarningsDay(DateOnly Day, long Total, int Jobs);

/// <summary>One completed job in the earnings list.</summary>
public sealed record EarningsJob(Guid Id, long Number, DateTimeOffset CompletedAt, Text ServiceName, long TotalPaisa);

/// <summary>Times out every request past its deadline (transition 3, D12); the `booking.expire_requests` job sends it.</summary>
public sealed record ExpireDueRequests : IRequest<int>;
