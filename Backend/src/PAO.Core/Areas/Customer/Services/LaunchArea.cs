using System.Text.Json;
using PAO.Lib.Common;

namespace PAO.Core.Areas.Customer.Services;

/// <summary>The launch-area test (C35) on the `service_area.geojson` setting (D5).</summary>
public static class LaunchArea
{
    /// <summary>
    /// Reports whether the GeoJSON Polygon or MultiPolygon contains `p`. An empty area covers
    /// everywhere; an unreadable one covers nothing, so a bad edit cannot open bookings
    /// nationwide.
    /// </summary>
    public static bool Covers(string areaGeoJson, GeoPoint p) =>
        areaGeoJson.Length == 0 || Polygons(areaGeoJson).Any(polygon => InPolygon(polygon, p));

    private static List<List<double[][]>> Polygons(string geoJson)
    {
        try
        {
            using var doc = JsonDocument.Parse(geoJson);
            var root = doc.RootElement;
            if (root.ValueKind != JsonValueKind.Object || !root.TryGetProperty("coordinates", out var coordinates)
                || coordinates.ValueKind != JsonValueKind.Array || !root.TryGetProperty("type", out var type))
            {
                return [];
            }
            return type.GetString() switch
            {
                "Polygon" => [Polygon(coordinates)],
                "MultiPolygon" => [.. coordinates.EnumerateArray().Select(Polygon)],
                _ => [],
            };
        }
        catch (Exception error) when (error is JsonException or InvalidOperationException)
        {
            return [];
        }
    }

    // A malformed position reads as zeros, as existing clients expect.
    private static List<double[][]> Polygon(JsonElement rings) =>
        [.. rings.EnumerateArray().Select(ring => ring.EnumerateArray()
            .Select(pos => new[] { At(pos, 0), At(pos, 1) }).ToArray())];

    private static double At(JsonElement position, int index) =>
        position.GetArrayLength() > index ? position[index].GetDouble() : 0;

    /// <summary>The even-odd rule: inside the outer ring and outside every hole.</summary>
    private static bool InPolygon(List<double[][]> rings, GeoPoint p) =>
        rings.Count > 0 && InRing(rings[0], p) && !rings.Skip(1).Any(hole => InRing(hole, p));

    /// <summary>Casts a ray east from p and counts edge crossings; GeoJSON stores [lng, lat].</summary>
    private static bool InRing(double[][] ring, GeoPoint p)
    {
        var inside = false;
        for (int i = 0, j = ring.Length - 1; i < ring.Length; j = i++)
        {
            var (xi, yi) = (ring[i][0], ring[i][1]);
            var (xj, yj) = (ring[j][0], ring[j][1]);
            if (yi > p.Lat != yj > p.Lat && p.Lng < ((xj - xi) * (p.Lat - yi) / (yj - yi)) + xi)
            {
                inside = !inside;
            }
        }
        return inside;
    }
}
