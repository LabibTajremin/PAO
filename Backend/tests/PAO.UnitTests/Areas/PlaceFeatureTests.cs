using PAO.Lib.Areas.Customer;

namespace PAO.UnitTests.Areas;

/// <summary>How a line of `osmium export -f geojsonseq` becomes a place (ADR-0042).</summary>
public sealed class PlaceFeatureTests
{
    private static PlaceRow? Parse(string properties, string geometry, string id = "\"id\":\"n1\",") =>
        PlaceFeatures.Parse($$"""{"type":"Feature",{{id}}"properties":{{{properties}}},"geometry":{{geometry}}}""");

    private const string Point = """{"type":"Point","coordinates":[90.4,23.8]}""";

    [Theory]
    [InlineData("""  Road ২৭, Dhanmondi!  """, "road 27 dhanmondi")]
    [InlineData("ধানমন্ডি", "ধানমন্ডি")]
    [InlineData("---", "")]
    public void Text_is_lower_case_with_ascii_digits_and_single_spaces(string text, string expected) =>
        Assert.Equal(expected, PlaceText.Normalise(text));

    [Fact]
    public void Kinds_follow_the_osm_tags()
    {
        Assert.Equal(PlaceKind.Area, Parse("\"place\":\"suburb\",\"name\":\"Gulshan\"", Point)!.Kind);
        Assert.Equal(PlaceKind.Street, Parse("\"highway\":\"primary\",\"name\":\"Mirpur Road\"", Point)!.Kind);
        Assert.Equal(PlaceKind.Place, Parse("\"shop\":\"mall\",\"name\":\"Jamuna\"", Point)!.Kind);
        var house = Parse("\"addr:housenumber\":\"7\",\"addr:street\":\"Road 2\",\"addr:quarter\":\"Block C\"", Point)!;
        Assert.Equal((PlaceKind.Address, "7, Road 2", "Block C"), (house.Kind, house.NameEn, house.Area));
        Assert.Null(Parse("\"place\":\"city\",\"name\":\"Dhaka\"", Point));
        Assert.Null(Parse("\"addr:housenumber\":\"7\"", Point));
        Assert.Null(Parse("\"amenity\":\"bench\",\"name\":7", Point));
    }

    [Fact]
    public void Names_prefer_english_and_fall_back_to_bangla()
    {
        var both = Parse("\"amenity\":\"school\",\"name\":\"স্কুল\",\"name:en\":\"School\",\"name:bn\":\"স্কুল\"", Point)!;
        Assert.Equal(("School", "স্কুল"), (both.NameEn, both.NameBn));
        var bangla = Parse("\"amenity\":\"school\",\"name:bn\":\"স্কুল\"", Point)!;
        Assert.Equal(("স্কুল", "স্কুল"), (bangla.NameEn, bangla.NameBn));
        Assert.Equal("w9", Parse("\"@id\":\"w9\",\"shop\":\"bakery\",\"name\":\"Bread\"", Point, id: "")!.Id);
        Assert.Null(Parse("\"shop\":\"bakery\",\"name\":\"Bread\"", Point, id: ""));
    }

    [Fact]
    public void Any_geometry_becomes_one_point()
    {
        const string Tags = "\"shop\":\"mall\",\"name\":\"Mall\"";
        var line = Parse(Tags, """{"type":"LineString","coordinates":[[90.0,23.0],[91.0,24.0]]}""")!;
        Assert.Equal((23.5, 90.5), (line.Point.Lat, line.Point.Lng));
        var multi = Parse(Tags, """{"type":"MultiPolygon","coordinates":[[[[90.0,23.0],[90.2,23.2]]]]}""")!;
        Assert.Equal(23.1, multi.Point.Lat, 6);
        Assert.Null(Parse(Tags, "null"));
        Assert.Null(Parse(Tags, """{"type":"Point"}"""));
        Assert.Null(Parse(Tags, """{"type":"LineString","coordinates":[]}"""));
        Assert.Null(Parse(Tags, """{"type":"LineString","coordinates":[[90.0]]}"""));
        Assert.Null(PlaceFeatures.Parse("""{"type":"Feature","id":"n1"}"""));
        Assert.Equal(PlaceKind.Area, PlaceFeatures.Parse("\u001e" + """{"id":"n1","properties":{"place":"quarter","name":"Q"},"geometry":{"type":"Point","coordinates":[90.4,23.8]}}""")!.Kind);
    }
}
