using PAO.Core.Areas.Verification.Services;
using PAO.Lib.Areas.Verification;
using PAO.Lib.Errors;
using static PAO.Core.Areas.Verification.Services.VerificationRules;

namespace PAO.UnitTests.Areas.Verification;

public sealed class VerificationRulesTests
{
    private static readonly DateTimeOffset Now = DateTimeOffset.Parse("2026-10-09T10:00:00Z", System.Globalization.CultureInfo.InvariantCulture);
    private static readonly Guid Actor = Guid.NewGuid();

    private static Dictionary<string, ItemState> ApprovedAll() =>
        ItemType.All.Where(ItemType.IsRequired).ToDictionary(t => t, t => ItemState.Missing(t) with { Status = ItemStatus.Approved });

    private static string Reason(Action act) => Assert.Throws<DomainException>(act).Reason;

    [Fact]
    public void Every_required_item_must_be_approved_for_a_level()
    {
        Assert.Equal(1, Level(ApprovedAll(), false));
        Assert.Equal(2, Level(ApprovedAll(), true));
        foreach (var t in ItemType.All.Where(ItemType.IsRequired))
        {
            foreach (var status in new[] { "missing", "pending", "rejected", "expired" })
            {
                var items = ApprovedAll();
                items[t] = ItemState.Missing(t) with { Status = status };
                Assert.Equal(0, Level(items, true));
            }
        }
        Assert.Equal(1, Level(ApprovedAll().Where(p => p.Key != ItemType.SkillProof).ToDictionary(), false));
    }

    [Fact]
    public void Runs_the_item_lifecycle()
    {
        ItemDecision D(bool approve, string reason = "") => new(Now, Actor, approve, reason);
        Assert.Equal(VerificationReasons.NotPending, Reason(() => Decided(ItemState.Missing("nid"), D(true))));
        var exp = Now.AddHours(1);
        var pending = Submitted(ItemState.Missing("nid"), Now, new Dictionary<string, string> { ["issueDate"] = "2026-06-01" }, exp);
        var approved = Decided(pending, D(true));
        Assert.Equal((ItemStatus.Approved, Actor), (approved.Status, approved.DecidedBy!.Value));
        Assert.Equal(VerificationReasons.NotPending, Reason(() => Decided(approved, D(true))));
        var rejected = Decided(approved, D(false, "fake"));
        Assert.Equal((ItemStatus.Rejected, "fake"), (rejected.Status, rejected.Reason));
        Assert.Equal(VerificationReasons.NotPending, Reason(() => Decided(rejected, D(false, "again"))));
        var again = Decided(Submitted(rejected, Now, new Dictionary<string, string>(), exp), D(true));
        Assert.Equal((false, true), (HasExpired(again, Now), HasExpired(again, exp)));
        Assert.False(HasExpired(ItemState.Missing("x") with { Status = ItemStatus.Approved }, Now));
    }

    [Fact]
    public void Checks_the_clearance_date_and_nid_formats()
    {
        var year = TimeSpan.FromDays(365);
        var today = new DateOnly(2026, 10, 9);
        Assert.Equal(new DateTimeOffset(2027, 4, 9, 0, 0, 0, TimeSpan.Zero), ClearanceExpiry(new DateOnly(2026, 4, 9), today, year));
        Assert.NotNull(ClearanceExpiry(today, today, year));
        Assert.Null(ClearanceExpiry(today.AddDays(-365), today, year));
        Assert.Null(ClearanceExpiry(today.AddDays(1), today, year));
        foreach (var (n, ok) in new[] { ("1234567890", true), ("1234567890123", true), ("12345678901234567", true), ("123456789", false), ("123456789x", false), ("١٢٣٤٥٦٧٨٩٠", false) })
        {
            Assert.Equal(ok, ValidNid(n));
        }
    }

    [Fact]
    public void Uses_the_dhaka_calendar_for_dates()
    {
        Assert.Equal(new DateOnly(2026, 10, 12), DhakaDates.Today(DateTimeOffset.Parse("2026-10-11T20:00:00Z", System.Globalization.CultureInfo.InvariantCulture)));
        Assert.Equal(new DateOnly(2026, 10, 11), DhakaDates.Today(DateTimeOffset.Parse("2026-10-11T17:59:59Z", System.Globalization.CultureInfo.InvariantCulture)));
        Assert.Equal(new DateOnly(2026, 3, 1), DhakaDates.EighteenthBirthday(new DateOnly(2008, 2, 29)));
        Assert.Equal(new DateOnly(2032, 2, 28), DhakaDates.EighteenthBirthday(new DateOnly(2014, 2, 28)));
        Assert.True(DhakaDates.IsAdult(new DateOnly(2008, 10, 12), new DateOnly(2026, 10, 12)));
        Assert.False(DhakaDates.IsAdult(new DateOnly(2008, 10, 13), new DateOnly(2026, 10, 12)));
    }

    [Fact]
    public void Records_sessions_and_the_cooling_off_period()
    {
        var s = new Level2SessionState { Id = Guid.NewGuid(), ProviderId = Guid.NewGuid(), ServiceId = Guid.NewGuid(), ScheduledAt = Now, Location = "Office", Status = "scheduled", CreatedAt = Now };
        Level2Outcome O(string result) => new() { Result = result, Checklist = [], Notes = string.Empty, Photos = [] };
        Assert.Equal(VerificationReasons.Invalid, Reason(() => Recorded(s, Now, Actor, O("maybe"))));
        var failed = Recorded(s, Now, Actor, O("fail"));
        Assert.Equal("completed", failed.Status);
        Assert.Equal(VerificationReasons.SessionClosed, Reason(() => Recorded(failed, Now, Actor, O("pass"))));
        var older = failed with { DecidedAt = Now.AddHours(-48) };
        var passed = failed with { Result = "pass" };
        Level2SessionState[] sessions = [failed, older, passed];
        Assert.Equal(Now.AddDays(14), RetryAfter(sessions, TimeSpan.FromDays(14), Now));
        Assert.Null(RetryAfter(sessions, TimeSpan.FromHours(1), Now.AddHours(2)));
        Assert.Null(RetryAfter([], TimeSpan.FromHours(1), Now));
    }

    [Fact]
    public void Keeps_the_state_and_its_level()
    {
        var st = new VerificationState(Guid.NewGuid());
        Assert.Equal(ItemStatus.Missing, st.ItemOf("nid").Status);
        Assert.False(CanReceiveBookings(st, 0));
        foreach (var (k, v) in ApprovedAll())
        {
            st.Items[k] = v;
        }
        Assert.Equal(0, Recalculate(st));
        Assert.True(CanReceiveBookings(st, 1));
        Assert.False(CanReceiveBookings(st, 2));
        Assert.Null(Recalculate(st));
        st.Blocked = true;
        Assert.False(CanReceiveBookings(st, 0));
    }
}
