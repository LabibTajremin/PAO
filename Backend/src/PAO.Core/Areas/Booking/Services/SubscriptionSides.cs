using PAO.Lib.Areas.Booking;
using PAO.Lib.Common;
using PAO.Lib.Mapping;

namespace PAO.Core.Areas.Booking.Services;

/// <summary>Who sees what of a subscription, the way <see cref="BookingSides"/> does for bookings.</summary>
public static class SubscriptionSides
{
    /// <summary>The customer's view: the merchant's phone once accepted.</summary>
    public static SubscriptionView Customer(this IMapper mapper, StoredSubscription s, IReadOnlyList<DayOfSubscription>? days = null) =>
        View(mapper, s, days, providerPhone: Accepted(s), customerPhone: true, exact: true);

    /// <summary>The merchant's view: the exact address and the customer's phone once accepted.</summary>
    public static SubscriptionView Provider(this IMapper mapper, StoredSubscription s, IReadOnlyList<DayOfSubscription>? days = null) =>
        View(mapper, s, days, providerPhone: true, customerPhone: Accepted(s), exact: Accepted(s));

    /// <summary>Support's view: everything.</summary>
    public static SubscriptionView Support(this IMapper mapper, StoredSubscription s, IReadOnlyList<DayOfSubscription>? days = null) =>
        View(mapper, s, days, providerPhone: true, customerPhone: true, exact: true);

    /// <summary>Whether the merchant accepted at some point, which shares the contacts.</summary>
    public static bool Accepted(StoredSubscription s) => s.AcceptedAt is not null;

    /// <summary>One date as the apps show it.</summary>
    public static DeliveryDateView Date(DayOfSubscription d) => new()
    {
        Date = EarningsCalendar.Iso(d.Date),
        Status = d.Status,
        Items = Inputs(d.Lines),
        Total = d.Lines.Sum(l => l.TotalPaisa),
        BookingId = d.BookingId,
        Changeable = d.Changeable,
    };

    /// <summary>The quantities of priced lines.</summary>
    public static IReadOnlyList<BookingItemInput> Inputs(IReadOnlyList<BookingLine> lines) =>
        [.. lines.Select(l => new BookingItemInput { SubServiceId = l.SubServiceId, Quantity = l.Quantity })];

    /// <summary>The address, exact or the area only.</summary>
    public static BookingAddressView Address(AddressSnapshot a, bool exact) => exact
        ? new BookingAddressView { Area = a.Area, Line1 = a.Line1, Line2 = a.Line2, Location = a.Location }
        : new BookingAddressView { Area = a.Area };

    private static SubscriptionView View(IMapper mapper, StoredSubscription s, IReadOnlyList<DayOfSubscription>? days, bool providerPhone, bool customerPhone, bool exact) => new()
    {
        Id = s.Id,
        Number = s.Display,
        Status = s.Status,
        ServiceId = s.ServiceId,
        ServiceName = s.ServiceName,
        Provider = Party(s.Provider, providerPhone),
        Customer = Party(s.Customer, customerPhone),
        Items = mapper.MapAll<BookingLine, BookingItemView>(s.Lines),
        Total = s.TotalPaisa,
        Unit = s.Unit,
        Pattern = s.Plan.Pattern,
        Weekdays = s.Plan.Weekdays.Count == 0 ? null : s.Plan.Weekdays,
        DayOfMonth = s.Plan.DayOfMonth,
        Window = s.Window,
        StartDate = EarningsCalendar.Iso(s.Plan.StartDate),
        EndDate = s.Plan.EndDate is { } end ? EarningsCalendar.Iso(end) : null,
        Count = s.Plan.Count,
        Address = Address(s.Address, exact),
        Note = s.Note.Length == 0 ? null : s.Note,
        CreatedAt = IsoTime.Format(s.CreatedAt),
        Upcoming = days is null ? null : [.. days.Select(Date)],
    };

    private static BookingPartyView Party(BookingParty p, bool phone) => new() { Id = p.Id, Name = p.Name, Phone = phone ? p.Phone : null };
}
