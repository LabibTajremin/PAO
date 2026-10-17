namespace PAO.Lib.Common;

/// <summary>A value in both product languages (PRD §11).</summary>
public sealed record Text
{
    /// <summary>The en.</summary>
    public required string En { get; init; }
    /// <summary>The bn.</summary>
    public required string Bn { get; init; }
}

/// <summary>A WGS84 position in decimal degrees.</summary>
public sealed record GeoPoint
{
    /// <summary>The lat.</summary>
    public required double Lat { get; init; }
    /// <summary>The lng.</summary>
    public required double Lng { get; init; }
}

/// <summary>The supported UI languages.</summary>
public static class Language
{
    /// <summary>The `"en"` value.</summary>
    public const string English = "en";
    /// <summary>The `"bn"` value.</summary>
    public const string Bangla = "bn";
}
