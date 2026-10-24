using PAO.Core.Areas.Booking.Services;
using PAO.Lib.Areas.Booking;
using PAO.Lib.Areas.Catalog;
using PAO.Lib.Common;
using R = PAO.Lib.Areas.Booking.BookingReasons;

namespace PAO.UnitTests.Areas;

public sealed class BookingRuleTests
{
    private static readonly DateTimeOffset Now = new(2026, 10, 9, 10, 0, 0, TimeSpan.Zero);
    private static readonly Stamp At = new(Now, Guid.NewGuid());
    private static readonly CodeLimits Limits = new(5, TimeSpan.FromMinutes(10));
    private static readonly Text Name = new() { En = "Fan", Bn = "ফ্যান" };

    private static Stamp Later(TimeSpan by) => new(Now + by, Guid.NewGuid());

    private static BookingLine Fan() => new()
    {
        Id = Guid.NewGuid(),
        SubServiceId = Guid.NewGuid(),
        PriceVersionId = Guid.NewGuid(),
        Name = Name,
        Unit = "unit",
        Quantity = 2,
        UnitPaisa = 50000,
        TotalPaisa = 100000,
    };

    private static StoredBooking Booking(string status, bool scheduled = false, int active = 0, DateTimeOffset? acceptedAt = null) => new()
    {
        Id = Guid.NewGuid(),
        Customer = new BookingParty(Guid.NewGuid(), "Nusrat", "+880"),
        Provider = new BookingParty(Guid.NewGuid(), "Rahim", "+880"),
        ServiceId = Guid.NewGuid(),
        ServiceName = Name,
        ServiceModel = "on_demand",
        Address = new AddressSnapshot(Guid.NewGuid(), "Banani", "House 12", string.Empty, new GeoPoint { Lat = 23.79, Lng = 90.40 }),
        Note = string.Empty,
        Status = status,
        Scheduled = scheduled,
        AcceptDeadline = Now + TimeSpan.FromMinutes(3),
        IdempotencyKey = "k",
        CreatedAt = Now,
        StartCode = "4821",
        ProviderActiveJobs = active,
        AcceptedAt = acceptedAt,
    };

    private static ExtrasProposal Proposal(params BookingLine[] lines) => new() { Id = Guid.NewGuid(), Status = "pending", ProposedAt = Now, Lines = [.. lines] };

    [Fact]
    public void Allows_exactly_the_transitions_of_the_state_table()
    {
        HashSet<string> allowed =
        [
            "requested accepted provider", "requested rejected provider", "requested timed_out system", "requested cancelled customer",
            "accepted on_the_way provider", "on_the_way arrived provider", "arrived in_progress provider", "in_progress completed provider",
            "accepted cancelled customer", "on_the_way cancelled customer", "arrived cancelled customer",
            "accepted cancelled provider", "on_the_way cancelled provider", "arrived cancelled provider",
        ];
        foreach (var from in BookingStates.All)
        {
            foreach (var to in BookingStates.All)
            {
                foreach (var actor in new[] { BookingActor.Customer, BookingActor.Provider, BookingActor.System })
                {
                    var key = $"{from} {to} {actor}";
                    Assert.Equal($"{key} {allowed.Contains(key)}", $"{key} {BookingStates.CanTransition(from, to, actor)}");
                }
            }
        }
        Assert.Null(BookingStates.Tab("nope", false));
        Assert.Equal(BookingStates.Active, BookingStates.Tab("upcoming", true));
        Assert.Equal(BookingStates.Active, BookingStates.Tab("jobs", false));
        Assert.Equal([BookingStatus.Requested], BookingStates.Tab("requests", true));
        Assert.Equal(BookingStates.All, BookingStates.Tab("all", false));
        Assert.Throws<PAO.Infrastructure.Http.Errors.ApiError>(() => new PAO.Core.Platform.UnimplementedController().NotImplemented());
        Assert.Matches("^[0-9]{4}$", BookingStates.NewStartCode());
    }

    [Fact]
    public void Accepts_rejects_and_times_out()
    {
        Assert.Equal(R.DeadlinePassed, BookingTransitions.Accept(Booking("requested"), Later(TimeSpan.FromMinutes(3))));
        Assert.Equal(R.ActiveJob, BookingTransitions.Accept(Booking("requested", active: 1), At));
        var scheduled = Booking("requested", scheduled: true, active: 1);
        Assert.Null(BookingTransitions.Accept(scheduled, At));
        Assert.Equal((Now, 1), (scheduled.AcceptedAt!.Value, scheduled.NewEvents.Count));
        Assert.Equal(R.InvalidTransition, BookingTransitions.Accept(scheduled, At));
        Assert.Equal(R.DeadlinePassed, BookingTransitions.Reject(Booking("requested"), Later(TimeSpan.FromHours(1)), "busy"));
        var b = Booking("requested");
        Assert.Null(BookingTransitions.Reject(b, At, "busy"));
        Assert.Equal("busy", b.RejectReason);
        Assert.Equal(R.InvalidTransition, BookingTransitions.Reject(Booking("accepted"), At, "busy"));
        Assert.Equal(R.InvalidTransition, BookingTransitions.TimeOut(Booking("requested"), At));
        Assert.Null(BookingTransitions.TimeOut(Booking("requested"), Later(TimeSpan.FromMinutes(3))));
    }

    [Fact]
    public void Cancels_until_the_job_starts_and_shares_contacts_only_after_acceptance()
    {
        foreach (var s in new[] { "in_progress", "completed" })
        {
            Assert.Equal(R.CancelNotAllowed, BookingTransitions.Cancel(Booking(s), At, BookingActor.Customer, "x"));
        }
        Assert.Equal(R.InvalidTransition, BookingTransitions.Cancel(Booking("requested"), At, BookingActor.Provider, "x"));
        var b = Booking("accepted", acceptedAt: Now);
        Assert.True(BookingStates.Cancellable(b, BookingActor.Customer));
        Assert.Null(BookingTransitions.Cancel(b, At, BookingActor.Provider, "emergency"));
        Assert.Equal(("provider", "cancelled"), (b.CancelledBy, b.Status));
        Assert.False(BookingStates.Cancellable(b, BookingActor.Customer));
        Assert.False(BookingStates.ContactsShared(Booking("accepted")));
        Assert.True(BookingStates.ContactsShared(Booking("completed", acceptedAt: Now)));
        Assert.False(BookingStates.ContactsShared(Booking("cancelled", acceptedAt: Now)));
    }

    [Fact]
    public void Locks_the_start_code_after_five_wrong_tries()
    {
        Assert.Equal(R.InvalidTransition, BookingTransitions.Start(Booking("on_the_way"), "4821", At, Limits));
        var b = Booking("arrived");
        for (var i = 0; i < 5; i++)
        {
            Assert.Equal(R.CodeWrong, BookingTransitions.Start(b, "0000", At, Limits));
        }
        Assert.Equal((0, Now + TimeSpan.FromMinutes(10)), (b.CodeAttempts, b.CodeLockedUntil!.Value));
        Assert.Equal(R.CodeLocked, BookingTransitions.Start(b, "4821", Later(TimeSpan.FromMinutes(9)), Limits));
        Assert.Null(BookingTransitions.Start(b, "4821", Later(TimeSpan.FromMinutes(10)), Limits));
        Assert.Equal(("in_progress", null), (b.Status, b.CodeLockedUntil));
    }

    [Fact]
    public void Proposes_decides_and_completes()
    {
        var price = new PriceSnapshot { SubServiceId = Guid.NewGuid(), ServiceId = Guid.NewGuid(), PriceVersionId = Guid.NewGuid(), Name = Name, Unit = "unit", AmountPaisa = 1, MaxQuantity = 10, Published = true };
        Assert.Null(BookingStates.NewLine(Guid.NewGuid(), price, 11));
        Assert.Null(BookingStates.NewLine(Guid.NewGuid(), price with { MaxQuantity = 0 }, 0));
        Assert.Equal(20, BookingStates.NewLine(Guid.NewGuid(), price with { MaxQuantity = 0 }, 20)!.TotalPaisa);
        var b = Booking("arrived");
        b.Lines = [Fan()];
        b.TotalPaisa = 100000;
        Assert.Equal(R.InvalidTransition, BookingTransitions.Propose(b, Proposal(Fan())));
        b.Status = "in_progress";
        Assert.Equal(R.Invalid, BookingTransitions.Propose(b, Proposal()));
        var p1 = Proposal(Fan());
        Assert.Null(BookingTransitions.Propose(b, p1));
        Assert.Equal(100000, b.Pending!.AddedPaisa);
        Assert.Equal(R.ExtrasPending, BookingTransitions.Propose(b, Proposal(Fan())));
        Assert.Equal(R.ExtrasPending, BookingTransitions.Complete(b, true, At));
        Assert.Equal(R.NoProposal, BookingTransitions.Decide(b, Guid.NewGuid(), true, Now));
        Assert.Null(BookingTransitions.Decide(b, p1.Id, true, Now));
        Assert.Equal(200000, b.TotalPaisa);
        Assert.True(b.Lines[1].Extra && b.Lines[1].ProposalId == p1.Id);
        var p3 = Proposal(Fan());
        BookingTransitions.Propose(b, p3);
        Assert.Null(BookingTransitions.Decide(b, p3.Id, false, Now));
        Assert.Equal(("declined", 200000L), (b.Proposals[1].Status, b.TotalPaisa));
        Assert.Equal(R.CashNotConfirmed, BookingTransitions.Complete(b, false, At));
        Assert.Null(BookingTransitions.Complete(b, true, At));
        Assert.Equal((true, Now), (b.CashReceived, b.CompletedAt!.Value));
        Assert.Equal(R.InvalidTransition, BookingTransitions.Advance(Booking("accepted"), "in_progress", At));
        Assert.Equal(R.InvalidTransition, BookingTransitions.Complete(Booking("accepted"), true, At));
        Assert.Null(BookingTransitions.Advance(Booking("accepted"), "on_the_way", At));
        Assert.Equal(0, BookingStates.Total([]));
        Assert.Null(Booking("in_progress").Pending);
        Assert.Equal("cancelled: note", new ReasonInput { Reason = "cancelled", Note = "note" }.Stored);
    }

    [Fact]
    public void Finds_days_saturday_weeks_and_months()
    {
        var thu = new DateOnly(2026, 10, 8);
        Assert.Equal((thu, thu), EarningsCalendar.Period("day", thu)!.Value);
        var week = EarningsCalendar.Period("week", thu)!.Value;
        Assert.Equal(("2026-10-03", "2026-10-09"), (EarningsCalendar.Iso(week.From), EarningsCalendar.Iso(week.To)));
        Assert.Equal(7, EarningsCalendar.Days(week.From, week.To).Count());
        Assert.Equal(week.From, EarningsCalendar.Period("week", new DateOnly(2026, 10, 3))!.Value.From);
        var feb = EarningsCalendar.Period("month", new DateOnly(2026, 2, 14))!.Value;
        Assert.Equal(("2026-02-01", "2026-02-28"), (EarningsCalendar.Iso(feb.From), EarningsCalendar.Iso(feb.To)));
        Assert.Null(EarningsCalendar.Period("year", thu));
        Assert.Equal(new DateOnly(2026, 10, 9), EarningsCalendar.DhakaDay(new DateTimeOffset(2026, 10, 8, 18, 30, 0, TimeSpan.Zero)));
        Assert.Equal(new DateOnly(2026, 10, 8), EarningsCalendar.DhakaDay(new DateTimeOffset(2026, 10, 8, 17, 59, 0, TimeSpan.Zero)));
        Assert.Equal(new DateTimeOffset(2025, 12, 31, 18, 0, 0, TimeSpan.Zero), EarningsCalendar.DayStart(new DateOnly(2026, 1, 1)));
        Assert.Null(EarningsCalendar.Parse(null));
        Assert.Equal("PAO-1", BookingNumbers.Format(1));
    }
}
