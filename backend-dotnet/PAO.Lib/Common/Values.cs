namespace PAO.Lib.Common;

/// <summary>A value in both product languages (PRD §11).</summary>
public sealed record Text
{
    public required string En { get; init; }
    public required string Bn { get; init; }
}

/// <summary>A WGS84 position in decimal degrees.</summary>
public sealed record GeoPoint
{
    public required double Lat { get; init; }
    public required double Lng { get; init; }
}

/// <summary>The supported UI languages.</summary>
public static class Language
{
    public const string English = "en";
    public const string Bangla = "bn";
}
