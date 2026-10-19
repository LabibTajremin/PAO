using System.Security.Cryptography;
using PAO.Lib.Areas.Booking;
using PAO.Lib.Areas.Catalog;
using static PAO.Lib.Areas.Booking.BookingActor;

namespace PAO.Core.Areas.Booking.Services;

/// <summary>The state table of docs/booking-states.md and the rules read from it.</summary>
public static class BookingStates
{
    // from → to → the actors allowed to make the move.
    private static readonly Dictionary<string, Dictionary<string, string[]>> Table = new()
    {
        [BookingStatus.Requested] = new()
        {
            [BookingStatus.Accepted] = [Provider],
            [BookingStatus.Rejected] = [Provider],
            [BookingStatus.TimedOut] = [BookingActor.System],
            [BookingStatus.Cancelled] = [BookingActor.Customer],
        },
        [BookingStatus.Accepted] = new() { [BookingStatus.OnTheWay] = [Provider], [BookingStatus.Cancelled] = [BookingActor.Customer, Provider] },
        [BookingStatus.OnTheWay] = new() { [BookingStatus.Arrived] = [Provider], [BookingStatus.Cancelled] = [BookingActor.Customer, Provider] },
        [BookingStatus.Arrived] = new() { [BookingStatus.InProgress] = [Provider], [BookingStatus.Cancelled] = [BookingActor.Customer, Provider] },
        [BookingStatus.InProgress] = new() { [BookingStatus.Completed] = [Provider] },
    };

    /// <summary>States that hold the provider: they count against the one-active-job rule.</summary>
    public static readonly IReadOnlyList<string> Active = [BookingStatus.Accepted, BookingStatus.OnTheWay, BookingStatus.Arrived, BookingStatus.InProgress];

    /// <summary>States shown on the upcoming tab.</summary>
    public static readonly IReadOnlyList<string> Upcoming = [BookingStatus.Requested, .. Active];

    /// <summary>States that ended the booking.</summary>
    public static readonly IReadOnlyList<string> Past = [BookingStatus.Completed, BookingStatus.Rejected, BookingStatus.TimedOut, BookingStatus.Cancelled];

    /// <summary>Every state, in the order of the spec.</summary>
    public static readonly IReadOnlyList<string> All = [.. Upcoming, .. Past];

    /// <summary>States in which the customer may read the start code.</summary>
    public static readonly IReadOnlyList<string> CodeStates = [BookingStatus.Accepted, BookingStatus.OnTheWay, BookingStatus.Arrived];

    /// <summary>Reports whether `actor` may move a booking from one state to another.</summary>
    public static bool CanTransition(string from, string to, string actor) =>
        Table.TryGetValue(from, out var moves) && moves.TryGetValue(to, out var actors) && actors.Contains(actor);

    /// <summary>The states listed on an app tab; a provider's upcoming tab holds accepted jobs, their requests have a tab of their own.</summary>
    public static IReadOnlyList<string>? Tab(string tab, bool asProvider) => (tab, asProvider) switch
    {
        ("requests", _) => [BookingStatus.Requested],
        ("upcoming", true) or ("jobs", _) => Active,
        ("upcoming", false) => Upcoming,
        ("past", _) => Past,
        ("all", _) => All,
        _ => null,
    };

    /// <summary>Reports whether `actor` may still cancel: until the start code is entered (D8).</summary>
    public static bool Cancellable(StoredBooking b, string actor) => CanTransition(b.Status, BookingStatus.Cancelled, actor);

    /// <summary>
    /// Reports whether contact details and the exact address are visible to the other side:
    /// only after acceptance and while the job is live or done (PRD §5, §11).
    /// </summary>
    public static bool ContactsShared(StoredBooking b) =>
        b.AcceptedAt is not null && (Active.Contains(b.Status) || b.Status == BookingStatus.Completed);

    /// <summary>Prices a line, or returns null for a quantity outside 1..maxQuantity (0 = no limit).</summary>
    public static BookingLine? NewLine(Guid id, PriceSnapshot price, int quantity)
    {
        if (quantity < 1 || (price.MaxQuantity > 0 && quantity > price.MaxQuantity))
        {
            return null;
        }
        return new BookingLine
        {
            Id = id,
            SubServiceId = price.SubServiceId,
            PriceVersionId = price.PriceVersionId,
            Name = price.Name,
            Unit = price.Unit,
            Quantity = quantity,
            UnitPaisa = price.AmountPaisa,
            TotalPaisa = price.AmountPaisa * quantity,
        };
    }

    /// <summary>Sums the lines.</summary>
    public static long Total(IEnumerable<BookingLine> lines) => lines.Sum(l => l.TotalPaisa);

    /// <summary>A fresh 4-digit start code from the CSPRNG.</summary>
    public static string NewStartCode() => RandomNumberGenerator.GetInt32(10_000).ToString("D4", System.Globalization.CultureInfo.InvariantCulture);
}
