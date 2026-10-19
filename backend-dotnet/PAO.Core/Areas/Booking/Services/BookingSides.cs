using PAO.Lib.Areas.Booking;
using PAO.Lib.Mapping;

namespace PAO.Core.Areas.Booking.Services;

/// <summary>
/// What each side may see of a booking. The provider sees the exact address, and either
/// side the other's phone, only once they are shared (PRD §5, §11); support sees everything.
/// </summary>
public static class BookingSides
{
    /// <summary>The customer's view.</summary>
    public static BookingView Customer(this IMapper mapper, StoredBooking b, bool? reviewed = null) =>
        mapper.Map<BookingForSide, BookingView>(new(b, BookingStates.ContactsShared(b), true, BookingStates.Cancellable(b, BookingActor.Customer), reviewed));

    /// <summary>The provider's view.</summary>
    public static BookingView Provider(this IMapper mapper, StoredBooking b, bool? reviewed = null)
    {
        var open = BookingStates.ContactsShared(b);
        return mapper.Map<BookingForSide, BookingView>(new(b, open, open, BookingStates.Cancellable(b, BookingActor.Provider), reviewed));
    }

    /// <summary>Support's view (A-06): both parties' contacts and the full timeline.</summary>
    public static BookingView Support(this IMapper mapper, StoredBooking b) =>
        mapper.Map<BookingForSide, BookingView>(new(b, true, true, BookingStates.Cancellable(b, BookingActor.Customer)));
}
