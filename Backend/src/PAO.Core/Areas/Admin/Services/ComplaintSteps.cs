using PAO.EF.Admin;
using PAO.Infrastructure.Http;
using PAO.Lib.Areas.Admin;
using PAO.Lib.Errors;
using PAO.Lib.Mapping;

namespace PAO.Core.Areas.Admin.Services;

/// <summary>Checks and pages shared by the complaint and people use cases.</summary>
public static class ComplaintSteps
{
    /// <summary>Throws `admin.complaint_already_resolved` for a resolved complaint.</summary>
    public static void Unresolved(ComplaintRecord c)
    {
        if (c.Status == "resolved")
        {
            throw new DomainException(AdminReasons.AlreadyResolved);
        }
    }

    /// <summary>Where a list continues, from the request's cursor.</summary>
    public static (DateTimeOffset? At, Guid? Id) After(string? cursor)
    {
        var c = Cursor.Decode(cursor);
        return c is null ? (null, null) : (DateTimeOffset.Parse(c.CreatedAt, System.Globalization.CultureInfo.InvariantCulture).ToUniversalTime(), Guid.Parse(c.Id));
    }

    /// <summary>Cuts a page from `rows`, fetched one longer than `size`, with the cursor of the last shown row when more follow.</summary>
    public static PageView<TView> Page<TRow, TView>(IReadOnlyList<TRow> rows, int size, Func<TRow, (DateTimeOffset At, Guid Id)> key, Func<IReadOnlyList<TRow>, IReadOnlyList<TView>> view)
    {
        var shown = rows.Take(size).ToList();
        string? next = null;
        if (rows.Count > size)
        {
            var (at, id) = key(shown[^1]);
            next = new Cursor(at.ToUniversalTime().ToString("O", System.Globalization.CultureInfo.InvariantCulture), id.ToString()).Encode();
        }
        return new PageView<TView> { Items = view(shown), NextCursor = next };
    }

    /// <summary>Complaints as the API shows them.</summary>
    public static IReadOnlyList<ComplaintView> Views(this IMapper mapper, IEnumerable<Complaint> complaints) => mapper.MapAll<Complaint, ComplaintView>(complaints);
}
