using PAO.Lib.Areas.Booking;
using R = PAO.Lib.Areas.Booking.BookingReasons;

namespace PAO.Core.Areas.Booking.Services;

/// <summary>When a change happens and the id of the timeline entry it records.</summary>
public sealed record Stamp(DateTimeOffset Now, Guid Id);

/// <summary>The start-code rules from the admin settings (D12).</summary>
public sealed record CodeLimits(int MaxAttempts, TimeSpan Lockout);

/// <summary>
/// The moves of docs/booking-states.md on a loaded booking. Each returns the reason it
/// refused, or null when the booking changed.
/// </summary>
public static class BookingTransitions
{
    /// <summary>Transition 1: before the deadline, and for an ASAP booking only when the provider has no other active job (PRD §5).</summary>
    public static string? Accept(StoredBooking b, Stamp s)
    {
        if (PastDeadline(b, s.Now))
        {
            return R.DeadlinePassed;
        }
        if (b.Status == BookingStatus.Requested && !b.Scheduled && b.ProviderActiveJobs > 0)
        {
            return R.ActiveJob;
        }
        var refused = Move(b, BookingStatus.Accepted, BookingActor.Provider, string.Empty, s);
        if (refused is null)
        {
            b.AcceptedAt = s.Now;
        }
        return refused;
    }

    /// <summary>Transition 2.</summary>
    public static string? Reject(StoredBooking b, Stamp s, string reason)
    {
        if (PastDeadline(b, s.Now))
        {
            return R.DeadlinePassed;
        }
        var refused = Move(b, BookingStatus.Rejected, BookingActor.Provider, reason, s);
        if (refused is null)
        {
            b.RejectReason = reason;
        }
        return refused;
    }

    /// <summary>Transition 3, applied by the expiry job once the deadline passed.</summary>
    public static string? TimeOut(StoredBooking b, Stamp s) =>
        s.Now < b.AcceptDeadline ? R.InvalidTransition : Move(b, BookingStatus.TimedOut, BookingActor.System, string.Empty, s);

    /// <summary>Transitions 4, 9 and 10; nobody may cancel once the job started (D8).</summary>
    public static string? Cancel(StoredBooking b, Stamp s, string actor, string reason)
    {
        if (b.Status is BookingStatus.InProgress or BookingStatus.Completed)
        {
            return R.CancelNotAllowed;
        }
        var refused = Move(b, BookingStatus.Cancelled, actor, reason, s);
        if (refused is null)
        {
            b.CancelReason = reason;
            b.CancelledBy = actor;
            b.CancelledAt = s.Now;
        }
        return refused;
    }

    /// <summary>Transitions 5 (on the way) and 6 (arrived).</summary>
    public static string? Advance(StoredBooking b, string to, Stamp s) =>
        to is BookingStatus.OnTheWay or BookingStatus.Arrived ? Move(b, to, BookingActor.Provider, string.Empty, s) : R.InvalidTransition;

    /// <summary>
    /// Transition 7. A wrong code counts an attempt; the last allowed wrong attempt locks
    /// entry for the lockout period. The booking changes even when the code is refused, so
    /// callers save it either way.
    /// </summary>
    public static string? Start(StoredBooking b, string code, Stamp s, CodeLimits limits)
    {
        if (b.Status != BookingStatus.Arrived)
        {
            return R.InvalidTransition;
        }
        if (b.CodeLockedUntil is { } until && s.Now < until)
        {
            return R.CodeLocked;
        }
        if (code != b.StartCode)
        {
            b.CodeAttempts++;
            if (b.CodeAttempts >= limits.MaxAttempts)
            {
                b.CodeAttempts = 0;
                b.CodeLockedUntil = s.Now + limits.Lockout;
            }
            return R.CodeWrong;
        }
        b.CodeAttempts = 0;
        b.CodeLockedUntil = null;
        b.StartedAt = s.Now;
        return Move(b, BookingStatus.InProgress, BookingActor.Provider, string.Empty, s);
    }

    /// <summary>Adds an extras proposal of catalog items (PRD §5: no free-text prices).</summary>
    public static string? Propose(StoredBooking b, ExtrasProposal p)
    {
        if (b.Status != BookingStatus.InProgress)
        {
            return R.InvalidTransition;
        }
        if (b.Pending is not null)
        {
            return R.ExtrasPending;
        }
        if (p.Lines.Count == 0)
        {
            return R.Invalid;
        }
        p.Status = "pending";
        p.AddedPaisa = BookingStates.Total(p.Lines);
        b.Proposals.Add(p);
        return null;
    }

    /// <summary>Approves or declines the pending proposal; approved items join the bill.</summary>
    public static string? Decide(StoredBooking b, Guid proposalId, bool approve, DateTimeOffset now)
    {
        var p = b.Pending;
        if (b.Status != BookingStatus.InProgress || p is null || p.Id != proposalId)
        {
            return R.NoProposal;
        }
        p.Status = approve ? "approved" : "declined";
        p.DecidedAt = now;
        if (approve)
        {
            b.Lines = [.. b.Lines, .. p.Lines.Select(l => l with { Extra = true, ProposalId = p.Id })];
            b.TotalPaisa = BookingStates.Total(b.Lines);
        }
        return null;
    }

    /// <summary>Transition 8: cash confirmed and no proposal pending (D4).</summary>
    public static string? Complete(StoredBooking b, bool cash, Stamp s)
    {
        if (b.Status == BookingStatus.InProgress && !cash)
        {
            return R.CashNotConfirmed;
        }
        if (b.Status == BookingStatus.InProgress && b.Pending is not null)
        {
            return R.ExtrasPending;
        }
        var refused = Move(b, BookingStatus.Completed, BookingActor.Provider, string.Empty, s);
        if (refused is null)
        {
            b.CashReceived = true;
            b.CompletedAt = s.Now;
        }
        return refused;
    }

    private static string? Move(StoredBooking b, string to, string actor, string reason, Stamp s)
    {
        if (!BookingStates.CanTransition(b.Status, to, actor))
        {
            return R.InvalidTransition;
        }
        b.Status = to;
        var entry = new TimelineEntry(s.Id, to, actor, reason, s.Now);
        b.Timeline.Add(entry);
        b.NewEvents.Add(entry);
        return null;
    }

    private static bool PastDeadline(StoredBooking b, DateTimeOffset now) => b.Status == BookingStatus.Requested && now >= b.AcceptDeadline;
}
