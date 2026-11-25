using PAO.Core.Areas.Booking.Repositories;
using PAO.Core.Areas.Booking.Services;
using PAO.Lib.Areas.Booking;
using PAO.Lib.Areas.Catalog;
using PAO.Lib.Common;
using PAO.Lib.Mapping;


namespace PAO.UnitTests.Areas;

public sealed class SubscriptionDayTests
{
    // Saturday 2026-12-05, 10:00 in Dhaka: before the 20:00 cutoff for Sunday the 6th.
    private static readonly DateTimeOffset Now = new(2026, 12, 5, 4, 0, 0, TimeSpan.Zero);
    private static readonly DateOnly Sunday = new(2026, 12, 6);
    private static readonly HashSet<DateOnly> NoHolidays = [];

    internal static StoredSubscription Subscription(string status = SubscriptionStatus.Active) => new()
    {
        Id = Guid.NewGuid(),
        Number = 500001,
        Customer = new BookingParty(Guid.NewGuid(), "Rahim", "+8801711111111"),
        Provider = new BookingParty(Guid.NewGuid(), "Ayesha's Kitchen", "+8801722222222"),
        ServiceId = Guid.NewGuid(),
        ServiceName = new Text { En = "Office lunch", Bn = "অফিস লাঞ্চ" },
        Address = new AddressSnapshot(Guid.NewGuid(), "Gulshan", "Road 11", "House 4", new GeoPoint { Lat = 23.79, Lng = 90.41 }),
        Note = string.Empty,
        Lines = [Line(2)],
        TotalPaisa = 30000,
        Unit = "meals",
        Plan = new DeliveryPlan { Pattern = DeliveryPattern.Weekdays, Weekdays = [0, 1, 2, 3, 4], StartDate = Sunday, Count = 10 },
        Window = new DeliveryWindow { Start = "12:00", End = "13:00" },
        Cutoff = new TimeOnly(20, 0),
        Status = status,
        IdempotencyKey = "key-1",
        CreatedAt = Now,
    };

    private static BookingLine Line(int quantity) => new()
    {
        Id = Guid.Empty,
        SubServiceId = Guid.Parse("11111111-1111-1111-1111-111111111111"),
        PriceVersionId = Guid.Empty,
        Name = new Text { En = "Lunch box", Bn = "লাঞ্চ বক্স" },
        Unit = "unit",
        Quantity = quantity,
        UnitPaisa = 15000,
        TotalPaisa = 15000 * quantity,
    };

    private static string StatusOn(StoredSubscription s, DateOnly date, DateTimeOffset? now = null) => SubscriptionDays.Day(s, date, now ?? Now).Status;

    [Fact]
    public void Planned_dates_are_scheduled_and_changeable_until_their_cutoff()
    {
        var s = Subscription();
        var day = SubscriptionDays.Day(s, Sunday, Now);
        Assert.Equal((DeliveryStatus.Scheduled, true, 30000L), (day.Status, day.Changeable, day.Lines.Sum(l => l.TotalPaisa)));
        Assert.False(SubscriptionDays.Day(s, Sunday, DeliveryCalendar.Cutoff(Sunday, s.Cutoff)).Changeable);
        Assert.Equal(DeliveryStatus.Skipped, StatusOn(Subscription(SubscriptionStatus.Paused), Sunday));
        Assert.Equal(DeliveryStatus.Declined, StatusOn(Subscription(SubscriptionStatus.Declined), Sunday));
        Assert.Equal(DeliveryStatus.Cancelled, StatusOn(Subscription(SubscriptionStatus.Cancelled), Sunday));
        Assert.False(SubscriptionDays.Day(Subscription(SubscriptionStatus.Finished), Sunday, Now).Changeable);
    }

    [Fact]
    public void Stored_dates_override_the_plan_and_booked_dates_follow_their_booking()
    {
        var s = Subscription();
        var monday = Sunday.AddDays(1);
        s.Dates[Sunday] = new SubscriptionDate(Sunday, DateState.Skipped, null, null, null);
        s.Dates[monday] = new SubscriptionDate(monday, DateState.Changed, [Line(5)], null, null);
        Assert.Equal(DeliveryStatus.Skipped, StatusOn(s, Sunday));
        Assert.Equal(75000, SubscriptionDays.Day(s, monday, Now).Lines.Sum(l => l.TotalPaisa));
        foreach (var (state, status) in new[] { (DateState.Declined, DeliveryStatus.Declined), (DateState.Cancelled, DeliveryStatus.Cancelled) })
        {
            s.Dates[Sunday] = new SubscriptionDate(Sunday, state, null, null, null);
            Assert.Equal(status, StatusOn(s, Sunday));
            Assert.False(SubscriptionDays.Day(s, Sunday, Now).Changeable);
        }
        s.Dates[Sunday] = new SubscriptionDate(Sunday, DateState.Booked, null, Guid.NewGuid(), BookingStatus.Accepted);
        Assert.Equal(DeliveryStatus.Scheduled, StatusOn(s, Sunday));
        Assert.Equal(DeliveryStatus.Preparing, StatusOn(s, Sunday, DeliveryCalendar.At(Sunday, new TimeOnly(9, 0))));
        Assert.False(SubscriptionDays.Day(s, Sunday, Now).Changeable);
        Assert.Equal(DeliveryStatus.OutForDelivery, SubscriptionDays.FromBooking(BookingStatus.Arrived, Sunday, Now));
        Assert.Equal(DeliveryStatus.Delivered, SubscriptionDays.FromBooking(BookingStatus.Completed, Sunday, Now));
        Assert.Equal(DeliveryStatus.Cancelled, SubscriptionDays.FromBooking(BookingStatus.Cancelled, Sunday, Now));
    }

    [Fact]
    public void A_range_merges_planned_and_stored_dates_in_order_and_knows_the_last_one()
    {
        var s = Subscription();
        var friday = new DateOnly(2026, 12, 11);
        s.Dates[friday] = new SubscriptionDate(friday, DateState.Booked, null, Guid.NewGuid(), BookingStatus.Completed);
        var days = SubscriptionDays.Between(s, Sunday, Sunday.AddDays(6), Now, NoHolidays);
        Assert.Equal(6, days.Count);
        Assert.Equal(friday, days[^1].Date);
        Assert.Equal(new DateOnly(2026, 12, 17), SubscriptionDays.Next(s, new DateOnly(2026, 12, 17), NoHolidays));
        Assert.Null(SubscriptionDays.Next(s, new DateOnly(2026, 12, 18), NoHolidays));
    }

    [Fact]
    public void Each_side_sees_contacts_and_the_exact_address_only_once_accepted()
    {
        var mapper = new Mapper([new BookingMappingProfile()]);
        var s = Subscription(SubscriptionStatus.Requested);
        var provider = mapper.Provider(s);
        Assert.Null(provider.Customer!.Phone);
        Assert.Null(provider.Address.Line1);
        Assert.Null(mapper.Customer(s).Provider!.Phone);
        Assert.Null(provider.Upcoming);
        s.AcceptedAt = Now;
        var days = SubscriptionDays.Between(s, Sunday, Sunday, Now, NoHolidays);
        var view = mapper.Customer(s, days);
        Assert.Equal(("+8801722222222", "PAO-S-500001", "2026-12-06"), (view.Provider!.Phone, view.Number, view.Upcoming!.Single().Date));
        Assert.Equal("Road 11", mapper.Provider(s).Address.Line1);
        var support = mapper.Support(s);
        Assert.Equal([0, 1, 2, 3, 4], support.Weekdays!);
        Assert.Equal(((string?)null, (string?)null), (support.EndDate, support.Note));
        var plain = Subscription();
        var once = new StoredSubscription
        {
            Id = plain.Id,
            Customer = plain.Customer,
            Provider = plain.Provider,
            ServiceId = plain.ServiceId,
            ServiceName = plain.ServiceName,
            Address = plain.Address,
            Note = "Gate 2",
            Lines = plain.Lines,
            TotalPaisa = plain.TotalPaisa,
            Unit = plain.Unit,
            Plan = new DeliveryPlan { Pattern = DeliveryPattern.Once, StartDate = Sunday, EndDate = Sunday },
            Window = plain.Window,
            Cutoff = plain.Cutoff,
            Status = plain.Status,
            IdempotencyKey = plain.IdempotencyKey,
            CreatedAt = plain.CreatedAt,
        };
        Assert.Equal((null, "2026-12-06", "Gate 2"), (mapper.Support(once).Weekdays, mapper.Support(once).EndDate, mapper.Support(once).Note));
    }

    [Fact]
    public void Rows_convert_to_the_model_and_back()
    {
        var s = Subscription();
        var row = SubscriptionRows.ToRecord(s);
        Assert.Equal(("12:00", "13:00"), (row.WindowStart.ToString("HH:mm"), row.WindowEnd.ToString("HH:mm")));
        var back = SubscriptionRows.ToModel(row);
        Assert.Equal((s.Plan, s.Window, s.Address, s.Customer), (back.Plan with { Weekdays = s.Plan.Weekdays }, back.Window, back.Address, back.Customer));
        Assert.Equal(s.Plan.Weekdays, back.Plan.Weekdays);
        Assert.Equal(s.Lines, SubscriptionRows.Lines(SubscriptionRows.LinesJson(s.Lines)));
    }
}
