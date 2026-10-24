using System.Globalization;
using System.Numerics;
using System.Text.Json;
using System.Text.RegularExpressions;
using PAO.Lib.Areas.Admin;

namespace PAO.Core.Areas.Admin.Services;

/// <summary>Setting types, complaint rules and the dashboard window (A-07, A-09, A-10).</summary>
public static partial class AdminRules
{
    /// <summary>How many days of bookings the dashboard charts (A-09).</summary>
    public const int DashboardDays = 30;

    /// <summary>Bounds the evidence a reporter attaches (C-14).</summary>
    public const int MaxComplaintPhotos = 5;

    private static readonly string[] Reasons =
        ["no_show", "late", "poor_quality", "overcharge", "damage", "behaviour", "safety", "customer_unavailable", "payment", "other"];

    // The spellings Go's strconv.ParseBool accepts.
    private static readonly HashSet<string> Booleans = ["1", "t", "T", "TRUE", "true", "True", "0", "f", "F", "FALSE", "false", "False"];

    /// <summary>Reports whether a new value fits the setting's type; numbers are never negative, as every setting is a duration, count, radius or threshold.</summary>
    public static bool FitsType(string type, string value) => type switch
    {
        "integer" => Integer().IsMatch(value) && BigInteger.Parse(value, CultureInfo.InvariantCulture) is var n && n >= 0 && n < BigInteger.Pow(2, 63),
        "number" => Number().IsMatch(value) && double.TryParse(value, NumberStyles.Float, CultureInfo.InvariantCulture, out var d) && double.IsFinite(d) && d >= 0,
        "boolean" => Booleans.Contains(value),
        "string" => true,
        "geojson" => value.Length == 0 || IsArea(value),
        _ => false,
    };

    /// <summary>Reports whether a new complaint's reason, description and photo list are acceptable.</summary>
    public static bool IsValidReport(ComplaintInput r)
    {
        var photos = r.PhotoMediaIds ?? [];
        var n = AdminText.Length(r.Description);
        return Reasons.Contains(r.Reason) && n is >= 10 and <= 1000 && photos.Count <= MaxComplaintPhotos && photos.Distinct().Count() == photos.Count;
    }

    /// <summary>Reports whether a resolution note has an acceptable length.</summary>
    public static bool IsValidResolution(string note) => AdminText.Length(note) is >= 5 and <= 1000;

    /// <summary>
    /// One entry per day of the window ending `today`, so charts show gaps as zeros, and the
    /// share of requested bookings that were completed, to two decimals.
    /// </summary>
    public static (IReadOnlyList<DayCount> Days, double CompletionRate) FillDays(DateOnly today, IReadOnlyList<DayCount> stored)
    {
        var byDay = stored.ToDictionary(d => d.Date);
        var days = Enumerable.Range(0, DashboardDays).Select(i => today.AddDays(i + 1 - DashboardDays).ToString("yyyy-MM-dd", CultureInfo.InvariantCulture))
            .Select(date => byDay.GetValueOrDefault(date) ?? new DayCount(date, 0, 0)).ToList();
        var total = days.Sum(d => d.Total);
        var rate = total == 0 ? 0 : Math.Round((double)days.Sum(d => d.Completed) / total, 2, MidpointRounding.AwayFromZero);
        return (days, rate);
    }

    /// <summary>A GeoJSON Polygon or MultiPolygon, the only shapes a service area can take (D5).</summary>
    private static bool IsArea(string value)
    {
        try
        {
            using var doc = JsonDocument.Parse(value);
            var root = doc.RootElement;
            return root.ValueKind == JsonValueKind.Object
                && root.TryGetProperty("type", out var type) && type.ValueKind == JsonValueKind.String && type.GetString() is "Polygon" or "MultiPolygon"
                && root.TryGetProperty("coordinates", out var coordinates) && coordinates.GetRawText().Replace(" ", string.Empty, StringComparison.Ordinal).Length > 2;
        }
        catch (JsonException)
        {
            return false;
        }
    }

    [GeneratedRegex(@"^[+-]?\d+$")]
    private static partial Regex Integer();

    // The decimal syntax Go's strconv.ParseFloat accepts; infinities are refused by the parse.
    [GeneratedRegex(@"^[+-]?(\d+\.?\d*|\.\d+)([eE][+-]?\d+)?$")]
    private static partial Regex Number();
}
