using Microsoft.Extensions.DependencyInjection;
using PAO.Core.Areas.Admin.Services;
using PAO.Core.Areas.Billing.Services.Shared;
using PAO.Core.Areas.Booking.Services;
using PAO.Core.Areas.Rating.Services;
using PAO.Lib.Areas.Admin;
using PAO.Lib.Areas.Billing;
using PAO.Lib.Areas.Rating;
using PAO.Lib.Common;
using PAO.Lib.Errors;

namespace PAO.UnitTests.Areas;

public sealed class AdminRuleTests
{
    [Theory]
    [InlineData("integer", "180")]
    [InlineData("number", "3.5")]
    [InlineData("boolean", "true")]
    [InlineData("boolean", "F")]
    [InlineData("string", "anything")]
    [InlineData("geojson", "")]
    [InlineData("geojson", """{"type":"Polygon","coordinates":[[[90,23],[91,23],[91,24],[90,23]]]}""")]
    public void Accepts_values_of_the_setting_type(string type, string value) => Assert.True(AdminRules.FitsType(type, value));

    [Theory]
    [InlineData("integer", "-1")]
    [InlineData("integer", "1.5")]
    [InlineData("integer", "9223372036854775808")]
    [InlineData("number", "-0.1")]
    [InlineData("number", "Inf")]
    [InlineData("number", "1e999")]
    [InlineData("number", "x")]
    [InlineData("boolean", "yes")]
    [InlineData("geojson", """{"type":"Point","coordinates":[90,23]}""")]
    [InlineData("geojson", """{"type":"Polygon"}""")]
    [InlineData("geojson", """{"type":"Polygon","coordinates":[]}""")]
    [InlineData("geojson", """{"type":5,"coordinates":[1]}""")]
    [InlineData("geojson", "null")]
    [InlineData("geojson", "{")]
    [InlineData("unknown", "1")]
    public void Refuses_values_of_another_type(string type, string value) => Assert.False(AdminRules.FitsType(type, value));

    [Fact]
    public void Checks_reports_resolutions_and_tickets()
    {
        var photo = Guid.NewGuid();
        var ok = new ComplaintInput { Reason = "late", Description = "Arrived two hours late.", PhotoMediaIds = [photo] };
        Assert.True(AdminRules.IsValidReport(ok));
        Assert.False(AdminRules.IsValidReport(ok with { Reason = "rude" }));
        Assert.False(AdminRules.IsValidReport(ok with { Description = "  late    " }));
        Assert.False(AdminRules.IsValidReport(ok with { Description = new string('x', 1001) }));
        Assert.False(AdminRules.IsValidReport(ok with { PhotoMediaIds = [.. Enumerable.Range(0, 6).Select(_ => Guid.NewGuid())] }));
        Assert.False(AdminRules.IsValidReport(ok with { PhotoMediaIds = [photo, photo] }));
        Assert.False(AdminRules.IsValidResolution("  ok   "));
        Assert.True(AdminRules.IsValidResolution("অনেক ভাল"));
        Assert.False(AdminRules.IsValidResolution(new string('x', 1001)));
        Assert.Equal("TCK-000042", Tickets.Format(42));
    }

    [Fact]
    public void Fills_the_dashboard_window_and_rounds_the_completion_rate()
    {
        var today = new DateOnly(2026, 10, 9);
        var (empty, none) = AdminRules.FillDays(today, []);
        Assert.Equal((30, 0.0, "2026-09-10", "2026-10-09"), (empty.Count, none, empty[0].Date, empty[^1].Date));
        var (days, rate) = AdminRules.FillDays(today, [new DayCount("2026-10-09", 3, 2), new DayCount("2026-10-01", 3, 0)]);
        Assert.Equal((3, 0.33), (days[^1].Total, rate));
    }
}

public sealed class RatingRuleTests
{
    private static readonly Reviewable Booking = new(Guid.NewGuid(), Guid.NewGuid(), Guid.NewGuid(), "Nusrat Jahan", "Rahim Uddin", new Text { En = "Fan install", Bn = "ফ্যান" }, DateTimeOffset.UtcNow);

    private static Review New(Guid author, string role, ReviewInput input) => RatingRules.NewReview(Booking, author, role, input, Guid.NewGuid(), DateTimeOffset.UtcNow);

    [Fact]
    public void Lets_each_side_review_the_other_under_a_first_name()
    {
        var r = New(Booking.CustomerId, ReviewRole.Customer, new ReviewInput { Stars = 5, Tags = ["on_time"], Comment = "  Great " });
        Assert.Equal((Booking.ProviderId, "Nusrat", "Great"), (r.SubjectId, r.AuthorName, r.Comment));
        Assert.Equal(ReviewRole.Provider, ReviewRole.SubjectOf(r.AuthorRole));
        var back = New(Booking.ProviderId, ReviewRole.Provider, new ReviewInput { Stars = 4 });
        Assert.Equal((Booking.CustomerId, "Rahim", 0), (back.SubjectId, back.AuthorName, back.Tags.Count));
        Assert.Equal(ReviewRole.Customer, ReviewRole.SubjectOf(back.AuthorRole));
        Assert.Equal(string.Empty, RatingRules.FirstName("   "));
    }

    [Fact]
    public void Refuses_strangers_and_bad_reviews()
    {
        Assert.Equal(RatingReasons.NotAllowed, Assert.Throws<DomainException>(() => New(Guid.NewGuid(), ReviewRole.Customer, new ReviewInput { Stars = 5 })).Reason);
        Assert.Equal(RatingReasons.NotAllowed, Assert.Throws<DomainException>(() => New(Booking.CustomerId, ReviewRole.Provider, new ReviewInput { Stars = 5 })).Reason);
        foreach (var bad in new[]
        {
            new ReviewInput { Stars = 0 }, new ReviewInput { Stars = 6 }, new ReviewInput { Stars = 5, Tags = ["a", "a"] },
            new ReviewInput { Stars = 5, Tags = ["a", "b", "c", "d", "e", "f", "g"] }, new ReviewInput { Stars = 5, Comment = new string('x', 501) },
        })
        {
            Assert.Equal(RatingReasons.Invalid, Assert.Throws<DomainException>(() => New(Booking.CustomerId, ReviewRole.Customer, bad)).Reason);
        }
        Assert.Equal(500, New(Booking.CustomerId, ReviewRole.Customer, new ReviewInput { Stars = 5, Comment = new string('য', 500) }).Comment.Length);
    }

    [Fact]
    public void Averages_to_one_decimal_and_is_zero_when_unrated()
    {
        Assert.Equal(0, Aggregate.Unrated.Average);
        Assert.Equal(4.7, new Aggregate(3, 14, [0, 0, 0, 1, 2]).Average);
        Assert.Equal(4.5, new Aggregate(2, 9, [0, 0, 0, 1, 1]).Average);
    }
}

public sealed class BillingSeamTests
{
    private sealed class Billing(bool blocked) : IBillingSharedService
    {
        public Task<DueStatus> GetDueStatus(Guid merchantId, CancellationToken cancellationToken) =>
            Task.FromResult(new DueStatus { DuePaisa = blocked ? 60000 : 0, BlockAmountPaisa = 50000, Blocked = blocked });

        public Task RecordCommission(CommissionRequest request, CancellationToken cancellationToken) => Task.CompletedTask;
    }

    [Fact]
    public async Task Checks_the_due_limit_before_an_accept_once_billing_is_wired()
    {
        await new BookingPeers(new ServiceCollection().BuildServiceProvider()).EnsureCanAccept(Guid.NewGuid(), CancellationToken.None);
        await new BookingPeers(new ServiceCollection().AddSingleton<IBillingSharedService>(new Billing(false)).BuildServiceProvider()).EnsureCanAccept(Guid.NewGuid(), CancellationToken.None);
        var blocked = new BookingPeers(new ServiceCollection().AddSingleton<IBillingSharedService>(new Billing(true)).BuildServiceProvider());
        Assert.Equal(BillingErrors.DueLimit, (await Assert.ThrowsAsync<DomainException>(() => blocked.EnsureCanAccept(Guid.NewGuid(), CancellationToken.None))).Reason);
    }
}
