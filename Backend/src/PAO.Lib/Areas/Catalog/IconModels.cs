namespace PAO.Lib.Areas.Catalog;

/// <summary>The body of uploadIcon: the file, base64.</summary>
public sealed record IconUpload
{
    /// <summary>image/svg+xml, image/png or image/webp.</summary>
    public required string ContentType { get; init; }
    /// <summary>The file, base64.</summary>
    public required string Data { get; init; }
}

/// <summary>The body of addIconFromLink.</summary>
public sealed record IconLink
{
    /// <summary>The https URL to download once.</summary>
    public required string Url { get; init; }
}

/// <summary>A stored icon, to put on a category or service.</summary>
public sealed record CatalogIconView
{
    /// <summary>Where devices read it (ADR-0039).</summary>
    public required string IconUrl { get; init; }
    /// <summary>The content type.</summary>
    public required string ContentType { get; init; }
}

/// <summary>The body of listIconLibrary.</summary>
public sealed record IconLibraryView
{
    /// <summary>The library keys.</summary>
    public required IReadOnlyList<string> Keys { get; init; }
}

/// <summary>The icon file types and their limits (ADR-0039).</summary>
public static class IconTypes
{
    /// <summary>The `"image/svg+xml"` value.</summary>
    public const string Svg = "image/svg+xml";
    /// <summary>The `"image/png"` value.</summary>
    public const string Png = "image/png";
    /// <summary>The `"image/webp"` value.</summary>
    public const string Webp = "image/webp";
    /// <summary>The largest SVG in bytes.</summary>
    public const int MaxSvgBytes = 100 * 1024;
    /// <summary>The largest PNG or WebP in bytes.</summary>
    public const int MaxRasterBytes = 200 * 1024;
    /// <summary>The smallest side of a PNG or WebP icon in pixels.</summary>
    public const int MinRasterSide = 96;

    /// <summary>The file extension of a supported type; null for any other.</summary>
    public static string? Extension(string contentType) => contentType switch
    {
        Svg => "svg",
        Png => "png",
        Webp => "webp",
        _ => null,
    };

    /// <summary>The largest file of a type in bytes.</summary>
    public static int MaxBytes(string contentType) => contentType == Svg ? MaxSvgBytes : MaxRasterBytes;
}

/// <summary>
/// The icons every app ships (`design/icons/`, `pao_ui/assets/icons/`); a category or
/// service names one as its icon key. A unit test keeps this list and the files in step.
/// </summary>
public static class IconLibrary
{
    /// <summary>The keys, in picker order.</summary>
    public static readonly IReadOnlyList<string> Keys =
    [
        "plumbing", "electrician", "ac", "appliance", "cleaning", "deep-clean", "pest-control", "painting",
        "carpentry", "gas-stove", "water-filter", "salon", "spa", "grooming", "driver", "car-wash",
        "moving", "laundry", "tailoring", "babysitting", "elderly-care", "nursing", "tutoring", "homemade-food",
        "catering", "bazar", "grocery", "chef", "gardening", "cctv", "wifi", "mobile-repair",
        "computer-repair", "photography", "decoration", "security", "courier", "tools", "beauty", "food",
    ];
}
