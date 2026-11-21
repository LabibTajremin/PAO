using System.Text.RegularExpressions;
using PAO.Lib.Areas.Verification;
using PAO.Lib.Errors;

namespace PAO.Core.Areas.Verification.Services;

/// <summary>A verifier's decision on one item.</summary>
public sealed record ItemDecision(DateTimeOffset Now, Guid Actor, bool Approve, string Reason);

/// <summary>The item, level and Level 2 rules of PRD §6.1–6.4, free of storage.</summary>
public static partial class VerificationRules
{
    /// <summary>The item back in the review queue with new data.</summary>
    public static ItemState Submitted(ItemState item, DateTimeOffset now, IReadOnlyDictionary<string, string> fields, DateTimeOffset? expiresAt) =>
        item with
        {
            Status = ItemStatus.Pending,
            Reason = string.Empty,
            Fields = fields,
            SubmittedAt = now,
            DecidedAt = null,
            DecidedBy = null,
            ExpiresAt = expiresAt,
        };

    /// <summary>
    /// Approves or rejects a pending item; an approved item may also be rejected when a
    /// verifier finds a problem later. Throws `verification.not_pending` otherwise.
    /// </summary>
    public static ItemState Decided(ItemState item, ItemDecision d)
    {
        var open = item.Status == ItemStatus.Pending;
        if (!open && (d.Approve || item.Status != ItemStatus.Approved))
        {
            throw new DomainException(VerificationReasons.NotPending);
        }
        return item with
        {
            Status = d.Approve ? ItemStatus.Approved : ItemStatus.Rejected,
            Reason = d.Approve ? string.Empty : d.Reason,
            DecidedAt = d.Now,
            DecidedBy = d.Actor,
        };
    }

    /// <summary>Whether an approved item's validity has ended (PRD §6.4).</summary>
    public static bool HasExpired(ItemState item, DateTimeOffset now) =>
        item.Status == ItemStatus.Approved && item.ExpiresAt is { } at && at <= now;

    /// <summary>Level 1 when every required item is approved, 2 when Level 2 was passed too (PRD §6.1).</summary>
    public static int Level(IReadOnlyDictionary<string, ItemState> items, bool level2Passed)
    {
        var approved = ItemType.All.All(t => !ItemType.IsRequired(t) || (items.TryGetValue(t, out var it) && it.Status == ItemStatus.Approved));
        if (!approved)
        {
            return 0;
        }
        return level2Passed ? 2 : 1;
    }

    /// <summary>
    /// Checks a police clearance issue date against the Dhaka date `today` and returns when
    /// the certificate stops counting (issue date plus validity), or null when it is dated in
    /// the future or already too old.
    /// </summary>
    public static DateTimeOffset? ClearanceExpiry(DateOnly issued, DateOnly today, TimeSpan validity)
    {
        var issuedAt = new DateTimeOffset(issued.ToDateTime(TimeOnly.MinValue), TimeSpan.Zero);
        var expires = issuedAt + validity;
        var todayAt = new DateTimeOffset(today.ToDateTime(TimeOnly.MinValue), TimeSpan.Zero);
        return issuedAt > todayAt || expires <= todayAt ? null : expires;
    }

    /// <summary>Accepts the 10, 13 and 17 digit NID formats.</summary>
    public static bool ValidNid(string number) => NidPattern().IsMatch(number);

    /// <summary>Updates the level and returns the old one when it changed.</summary>
    public static int? Recalculate(VerificationState state)
    {
        var from = state.Level;
        state.Level = Level(state.Items, state.Level2PassedAt is not null);
        return from == state.Level ? null : from;
    }

    /// <summary>Not blocked and at least `minLevel`, never below Level 1 (PRD §6.1, §6.4).</summary>
    public static bool CanReceiveBookings(VerificationState state, int minLevel) =>
        !state.Blocked && state.Level >= Math.Max(1, minLevel);

    /// <summary>The session closed with a result; throws `session_closed` or `invalid`.</summary>
    public static Level2SessionState Recorded(Level2SessionState session, DateTimeOffset now, Guid actor, Level2Outcome o)
    {
        if (session.Status != "scheduled")
        {
            throw new DomainException(VerificationReasons.SessionClosed);
        }
        if (o.Result is not ("pass" or "fail" or "retest"))
        {
            throw new DomainException(VerificationReasons.Invalid);
        }
        return session with
        {
            Result = o.Result,
            Checklist = o.Checklist,
            Notes = o.Notes,
            VisitLat = o.VisitLat,
            VisitLng = o.VisitLng,
            Photos = o.Photos,
            Status = "completed",
            DecidedBy = actor,
            DecidedAt = now,
        };
    }

    /// <summary>The end of the cooling-off period after the latest failed session, or null when a session may be booked now.</summary>
    public static DateTimeOffset? RetryAfter(IEnumerable<Level2SessionState> sessions, TimeSpan coolingOff, DateTimeOffset now)
    {
        var last = sessions.Where(s => s.Result == "fail" && s.DecidedAt is not null).Select(s => s.DecidedAt).Max();
        if (last is null)
        {
            return null;
        }
        var until = last.Value + coolingOff;
        return until > now ? until : null;
    }

    [GeneratedRegex("^(?:[0-9]{10}|[0-9]{13}|[0-9]{17})$")]
    private static partial Regex NidPattern();
}
