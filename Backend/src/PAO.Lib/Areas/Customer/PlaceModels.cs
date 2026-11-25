using System.Globalization;
using System.Text;
using System.Text.Json;
using PAO.Lib.Common;

namespace PAO.Lib.Areas.Customer;

/// <summary>What a place is, best first in search results (ADR-0042).</summary>
public static class PlaceKind
{
    /// <summary>A neighbourhood or area, e.g. Gulshan 2.</summary>
    public const string Area = "area";
    /// <summary>A named road.</summary>
    public const string Street = "street";
    /// <summary>A shop, office, school or other named place.</summary>
    public const string Place = "place";
    /// <summary>A house address without a name.</summary>
    public const string Address = "address";
}

/// <summary>One place to import or answer.</summary>
public sealed record PlaceRow(string Id, string Kind, string NameEn, string NameBn, string Area, GeoPoint Point);

/// <summary>A place as the apps show it.</summary>
public sealed record PlaceView
{
    /// <summary>The OpenStreetMap id, e.g. n123.</summary>
    public required string Id { get; init; }
    /// <summary>One of <see cref="PlaceKind"/>.</summary>
    public required string Kind { get; init; }
    /// <summary>The name in the asked language, falling back to the other.</summary>
    public required string Title { get; init; }
    /// <summary>The area it is in, if known.</summary>
    public string? Area { get; init; }
    /// <summary>Where it is.</summary>
    public required GeoPoint Location { get; init; }
}

/// <summary>Places found by search.</summary>
public sealed record PlaceListView(IReadOnlyList<PlaceView> Items);

/// <summary>The search text of places and queries: lower case, ASCII digits, single spaces.</summary>
public static class PlaceText
{
    /// <summary>Normalises <paramref name="text"/> so Bangla and English queries meet the stored names.</summary>
    public static string Normalise(string text)
    {
        var sb = new StringBuilder(text.Length);
        foreach (var c in text.Trim().ToLowerInvariant())
        {
            // Bangla digits ০–৯ are U+09E6–U+09EF.
            var ch = c is >= '০' and <= '৯' ? (char)('0' + (c - '০')) : c;
            var keep = char.IsLetterOrDigit(ch) || CharUnicodeInfo.GetUnicodeCategory(ch) is UnicodeCategory.NonSpacingMark or UnicodeCategory.SpacingCombiningMark;
            if (keep)
            {
                sb.Append(ch);
            }
            else if (sb.Length > 0 && sb[^1] != ' ')
            {
                sb.Append(' ');
            }
        }
        return sb.ToString().TrimEnd();
    }
}

/// <summary>Reads one line of `osmium export -f geojsonseq` into a place (ADR-0042 §2).</summary>
public static class PlaceFeatures
{
    private static readonly string[] AreaPlaces = ["suburb", "neighbourhood", "quarter", "city_block", "locality", "village"];
    private static readonly string[] PlaceKeys = ["amenity", "shop", "office", "tourism", "leisure", "building", "healthcare", "craft"];

    /// <summary>The place in <paramref name="line"/>, or null for a line without a usable name or point.</summary>
    public static PlaceRow? Parse(string line)
    {
        using var doc = JsonDocument.Parse(line.TrimStart('\u001e'));
        var root = doc.RootElement;
        if (!root.TryGetProperty("properties", out var props) || !root.TryGetProperty("geometry", out var geometry)
            || Centre(geometry) is not { } point)
        {
            return null;
        }
        string Tag(string key) => props.TryGetProperty(key, out var v) && v.ValueKind == JsonValueKind.String ? v.GetString()!.Trim() : string.Empty;
        // `osmium export --add-unique-id=type_id` puts "n123"/"w45" at the top level.
        var id = root.TryGetProperty("id", out var top) && top.ValueKind == JsonValueKind.String ? top.GetString()! : Tag("@id");
        var (kind, en, bn) = Named(Tag);
        if (kind is null || id.Length == 0)
        {
            return null;
        }
        return new PlaceRow(id, kind, en, bn, Tag("addr:suburb") is { Length: > 0 } suburb ? suburb : Tag("addr:quarter"), point);
    }

    private static (string? Kind, string En, string Bn) Named(Func<string, string> tag)
    {
        var bn = tag("name:bn");
        var en = tag("name:en") is { Length: > 0 } english ? english : tag("name");
        if (en.Length == 0 && bn.Length == 0)
        {
            var house = tag("addr:housenumber");
            var street = tag("addr:street");
            return house.Length > 0 && street.Length > 0 ? (PlaceKind.Address, $"{house}, {street}", string.Empty) : (null, string.Empty, string.Empty);
        }
        var kind = AreaPlaces.Contains(tag("place")) ? PlaceKind.Area
            : tag("highway").Length > 0 ? PlaceKind.Street
            : PlaceKeys.Any(k => tag(k).Length > 0) ? PlaceKind.Place
            : null;
        return (kind, en.Length > 0 ? en : bn, bn);
    }

    /// <summary>A point for any geometry: the point itself, else the mean of its first ring or line.</summary>
    private static GeoPoint? Centre(JsonElement geometry)
    {
        if (geometry.ValueKind != JsonValueKind.Object || !geometry.TryGetProperty("coordinates", out var c))
        {
            return null;
        }
        var ring = c;
        while (ring.ValueKind == JsonValueKind.Array && ring.GetArrayLength() > 0 && ring[0].ValueKind == JsonValueKind.Array
               && ring[0].GetArrayLength() > 0 && ring[0][0].ValueKind == JsonValueKind.Array)
        {
            ring = ring[0];
        }
        double[][] points = ring.ValueKind == JsonValueKind.Array && ring.GetArrayLength() > 0 && ring[0].ValueKind == JsonValueKind.Number
            ? [[ring[0].GetDouble(), ring[1].GetDouble()]]
            : [.. ring.EnumerateArray().Where(p => p.ValueKind == JsonValueKind.Array && p.GetArrayLength() >= 2).Select(p => new[] { p[0].GetDouble(), p[1].GetDouble() })];
        return points.Length == 0 ? null : new GeoPoint { Lng = points.Average(p => p[0]), Lat = points.Average(p => p[1]) };
    }
}
