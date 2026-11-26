using PAO.Core.Areas.Booking.Services;
using PAO.Core.Areas.Catalog.Services;
using PAO.Lib.Areas.Booking;
using PAO.Lib.Areas.Catalog;
using PAO.Lib.Common;

namespace PAO.UnitTests.Areas;

public sealed class DeliveryCalendarTests
{
    private static readonly HashSet<DateOnly> NoHolidays = [];

    internal static ServiceSchedule Lunch() => new()
    {
        Patterns = [DeliveryPattern.Weekdays, DeliveryPattern.Once],
        Windows = [new DeliveryWindow { Start = "12:00", End = "13:00" }],
        LeadHours = 12,
        Cutoff = "20:00",
        Unit = "meals",
        MinQuantity = 1,
        MaxQuantity = 50,
    };

    private static DeliveryPlan Plan(string pattern, string start, int[]? weekdays = null, int? day = null, string? end = null, int? count = null) => new()
    {
        Pattern = pattern,
        Weekdays = weekdays ?? [],
        DayOfMonth = day,
        StartDate = DateOnly.Parse(start),
        EndDate = end is null ? null : DateOnly.Parse(end),
        Count = count,
    };

    private static string[] Dates(DeliveryPlan plan, string until, HashSet<DateOnly>? holidays = null) =>
        [.. DeliveryCalendar.Dates(plan, DateOnly.Parse(until), holidays ?? NoHolidays).Select(EarningsCalendar.Iso)];

    [Fact]
    public void A_schedule_keeps_its_ranges_and_known_values()
    {
        Assert.True(Lunch().IsValid);
        Assert.Equal(new TimeOnly(20, 0), Lunch().CutoffTime);
        ServiceSchedule[] broken =
        [
            Lunch() with { Patterns = [] }, Lunch() with { Patterns = ["hourly"] }, Lunch() with { Patterns = ["once", "once"] },
            Lunch() with { Windows = [] }, Lunch() with { Windows = [new DeliveryWindow { Start = "13:00", End = "12:00" }] },
            Lunch() with { Windows = [new DeliveryWindow { Start = "noon", End = "13:00" }] }, Lunch() with { LeadHours = -1 },
            Lunch() with { LeadHours = 337 }, Lunch() with { Cutoff = "8pm" }, Lunch() with { Unit = "kg" },
            Lunch() with { MinQuantity = 0 }, Lunch() with { MaxQuantity = 501 }, Lunch() with { MinQuantity = 9, MaxQuantity = 2 },
        ];
        Assert.All(broken, s => Assert.False(s.IsValid));
        Assert.Null(ScheduleTime.Parse(null));
        Assert.Null(ScheduleTime.Parse("7:30"));
        Assert.Equal(new TimeOnly(7, 30), ScheduleTime.Parse("07:30"));
    }

    [Fact]
    public void Only_scheduled_delivery_services_carry_a_schedule()
    {
        var service = new ServiceNode
        {
            Id = Guid.Empty,
            CategoryId = Guid.Empty,
            Name = new Text { En = "Office lunch", Bn = "অফিস লাঞ্চ" },
            IconKey = "homemade-food",
            Model = ServiceModel.ScheduledDelivery,
            RequiredLevel = 1,
            SearchRadiusM = 5000,
            WomenProvidersOnly = false,
            RequiresLevel2 = false,
            Level2Checklist = [],
            Schedule = Lunch(),
            SortOrder = 0,
            Published = true,
        };
        Assert.True(CatalogRules.IsValidService(service));
        Assert.False(CatalogRules.IsValidService(service with { Schedule = null }));
        Assert.False(CatalogRules.IsValidService(service with { Schedule = Lunch() with { Unit = "kg" } }));
        Assert.False(CatalogRules.IsValidService(service with { Model = ServiceModel.OnDemand }));
        Assert.True(CatalogRules.IsValidService(service with { Model = ServiceModel.OnDemand, Schedule = null }));
    }

    [Fact]
    public void Weekday_lunch_skips_fridays_saturdays_and_holidays_and_keeps_the_count()
    {
        // 2026-12-06 is a Sunday; Sunday to Thursday are the Dhaka office week.
        var office = Plan(DeliveryPattern.Weekdays, "2026-12-06", weekdays: [0, 1, 2, 3, 4], count: 6);
        Assert.Equal(["2026-12-06", "2026-12-07", "2026-12-08", "2026-12-09", "2026-12-10", "2026-12-13"], Dates(office, "2027-01-31"));
        var victory = new HashSet<DateOnly> { new(2026, 12, 16) };
        var twoWeeks = office with { Count = null, EndDate = new DateOnly(2026, 12, 17) };
        Assert.Equal(9, Dates(twoWeeks, "2027-01-31", victory).Length);
        Assert.DoesNotContain("2026-12-16", Dates(twoWeeks, "2027-01-31", victory));
        Assert.Equal(["2026-12-06", "2026-12-07"], Dates(twoWeeks, "2026-12-07"));
    }

    [Fact]
    public void Monthly_dates_fall_on_the_last_day_of_short_months()
    {
        var bazar = Plan(DeliveryPattern.Monthly, "2027-01-31", day: 31, count: 3);
        Assert.Equal(["2027-01-31", "2027-02-28", "2027-03-31"], Dates(bazar, "2027-12-31"));
        var leap = Plan(DeliveryPattern.Monthly, "2028-01-15", day: 30);
        Assert.Equal(["2028-01-30", "2028-02-29"], Dates(leap, "2028-03-01"));
        Assert.Empty(Dates(Plan(DeliveryPattern.Monthly, "2027-01-20", day: 10), "2027-02-05"));
    }

    [Fact]
    public void Once_daily_and_weekly_plans_expand_as_named()
    {
        Assert.Equal(["2026-12-24"], Dates(Plan(DeliveryPattern.Once, "2026-12-24"), "2027-01-31"));
        Assert.Empty(Dates(Plan(DeliveryPattern.Once, "2026-12-24"), "2026-12-23"));
        Assert.Equal(["2026-12-01", "2026-12-02", "2026-12-03"], Dates(Plan(DeliveryPattern.Daily, "2026-12-01", end: "2026-12-03"), "2027-01-01"));
        Assert.Equal(["2026-12-04", "2026-12-11"], Dates(Plan(DeliveryPattern.Weekly, "2026-12-01", weekdays: [5]), "2026-12-17"));
        Assert.Empty(Dates(Plan(DeliveryPattern.Daily, "2026-12-05"), "2026-12-01"));
    }

    [Theory]
    [InlineData(DeliveryPattern.Once, null, null, null, null, true)]
    [InlineData(DeliveryPattern.Weekdays, new[] { 0, 1, 2 }, null, null, 10, true)]
    [InlineData(DeliveryPattern.Weekdays, new int[0], null, null, null, false)]
    [InlineData(DeliveryPattern.Weekdays, new[] { 1, 1 }, null, null, null, false)]
    [InlineData(DeliveryPattern.Weekdays, new[] { 7 }, null, null, null, false)]
    [InlineData(DeliveryPattern.Weekly, new[] { 1, 2 }, null, null, null, false)]
    [InlineData(DeliveryPattern.Monthly, null, 0, null, null, false)]
    [InlineData(DeliveryPattern.Monthly, null, 31, null, null, false)]
    [InlineData(DeliveryPattern.Daily, null, 3, null, null, false)]
    [InlineData(DeliveryPattern.Daily, null, null, "2026-12-31", 5, false)]
    [InlineData(DeliveryPattern.Daily, null, null, "2026-11-30", null, false)]
    [InlineData("hourly", null, null, null, null, false)]
    public void A_plan_must_fit_its_pattern_and_the_service(string pattern, int[]? weekdays, int? day, string? end, int? count, bool valid) =>
        Assert.Equal(valid, DeliveryCalendar.IsValid(Plan(pattern, "2026-12-01", weekdays, day, end, count), Lunch().Patterns.Append(DeliveryPattern.Daily).ToList()));

    [Fact]
    public void Cutoffs_windows_and_holidays_are_read_in_dhaka_time()
    {
        var date = new DateOnly(2026, 12, 7);
        Assert.Equal(new DateTimeOffset(2026, 12, 6, 14, 0, 0, TimeSpan.Zero), DeliveryCalendar.Cutoff(date, new TimeOnly(20, 0)));
        Assert.Equal(new DateOnly(2026, 12, 7), DeliveryCalendar.Today(new DateTimeOffset(2026, 12, 6, 18, 30, 0, TimeSpan.Zero)));
        Assert.Equal([new DateOnly(2026, 12, 16), new DateOnly(2027, 3, 26)], DeliveryCalendar.Holidays(" 2026-12-16, bad,2027-03-26,").Order());
        Assert.Empty(DeliveryCalendar.Holidays(string.Empty));
        Assert.Equal("12:00–13:00", DeliveryCalendar.Label(Lunch().Windows[0]));
        Assert.True(MonthlyFirst() > 0);
    }

    private static int MonthlyFirst() => DeliveryCalendar.Dates(Plan(DeliveryPattern.Monthly, "2026-12-01"), new DateOnly(2027, 1, 31), NoHolidays).Count();
}
