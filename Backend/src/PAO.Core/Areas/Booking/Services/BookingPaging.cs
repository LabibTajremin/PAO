using PAO.Infrastructure.Http;
using PAO.Lib.Areas.Booking;
using PAO.Lib.Mapping;

namespace PAO.Core.Areas.Booking.Services;

/// <summary>Cursor pages over (time, id), one look-ahead row deep.</summary>
public static class BookingPaging
{
    /// <summary>The page size and the page request from `cursor` and `limit`.</summary>
    public static (int Size, BookingPage Page) Page(string? cursor, int? limit)
    {
        var c = Cursor.Decode(cursor);
        var size = Cursor.PageSize(limit);
        var at = c is null ? (DateTimeOffset?)null : DateTimeOffset.Parse(c.CreatedAt, System.Globalization.CultureInfo.InvariantCulture).ToUniversalTime();
        return (size, new BookingPage(at, c is null ? null : Guid.Parse(c.Id), size + 1));
    }

    /// <summary>The cursor after the last shown row when the look-ahead row came back.</summary>
    public static string? Next<T>(IReadOnlyList<T> rows, int size, Func<T, (DateTimeOffset At, Guid Id)> key)
    {
        if (rows.Count <= size)
        {
            return null;
        }
        var (at, id) = key(rows[size - 1]);
        return new Cursor(at.ToUniversalTime().ToString("O", System.Globalization.CultureInfo.InvariantCulture), id.ToString()).Encode();
    }

    /// <summary>A page of rows; `counterpart` names the other side of each.</summary>
    public static BookingListView List(IMapper mapper, IReadOnlyList<BookingRow> rows, int size, Func<BookingRow, string> counterpart) => new()
    {
        Items = mapper.MapAll<BookingRowForSide, BookingListItemView>(rows.Take(size).Select(r => new BookingRowForSide(r, counterpart(r)))),
        NextCursor = Next(rows, size, r => (r.CreatedAt, r.Id)),
    };
}
