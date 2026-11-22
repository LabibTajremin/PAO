using System.Text.Json.Serialization;
using PAO.Lib.Common;
using PAO.Lib.Events;

namespace PAO.Lib.Areas.Admin;

/// <summary>A fixed place in an app that shows an admin-replaceable illustration (06-update §5).</summary>
public sealed record ArtworkSpec(string Key, string App, int Width, int Height);

/// <summary>The artwork slots, their app and their size in pixels (ADR-0040).</summary>
public static class ArtworkSlots
{
    /// <summary>The `"customer"` value.</summary>
    public const string Customer = "customer";
    /// <summary>The `"partner"` value.</summary>
    public const string Partner = "partner";
    /// <summary>The `"admin"` value.</summary>
    public const string Admin = "admin";

    /// <summary>Every slot, in the admin page's order.</summary>
    public static readonly IReadOnlyList<ArtworkSpec> All =
    [
        new("customer.signin.hero", Customer, 1170, 1200),
        new("customer.onboarding.1", Customer, 1170, 1080),
        new("customer.onboarding.2", Customer, 1170, 1080),
        new("customer.onboarding.3", Customer, 1170, 1080),
        new("partner.signin.hero", Partner, 1170, 1200),
        new("partner.onboarding.1", Partner, 1170, 1080),
        new("partner.onboarding.2", Partner, 1170, 1080),
        new("partner.onboarding.3", Partner, 1170, 1080),
        new("empty.bookings", Customer, 720, 540),
        new("empty.search", Customer, 720, 540),
        new("empty.notifications", Customer, 720, 540),
        new("empty.jobs", Partner, 720, 540),
        new("offline", Customer, 720, 540),
        new("success.booking", Customer, 720, 720),
        new("success.job", Partner, 720, 720),
        new("admin.login.hero", Admin, 1600, 1200),
    ];

    /// <summary>The slot with `key`, or null.</summary>
    public static ArtworkSpec? Find(string key) => All.FirstOrDefault(s => s.Key == key);

    /// <summary>
    /// The slots an app reads: its own, and the offline and notification states both mobile
    /// apps show.
    /// </summary>
    public static IEnumerable<ArtworkSpec> For(string app) =>
        All.Where(s => s.App == app || (app == Partner && s.Key is "offline" or "empty.notifications"));
}

/// <summary>The file types and limits of artwork uploads (06-update §5).</summary>
public static class ArtworkFiles
{
    /// <summary>The `"image/svg+xml"` value.</summary>
    public const string Svg = "image/svg+xml";
    /// <summary>The largest SVG in bytes.</summary>
    public const int MaxSvgBytes = 300 * 1024;
    /// <summary>The largest PNG or WebP in bytes.</summary>
    public const int MaxRasterBytes = 800 * 1024;
    /// <summary>How far the ratio may differ from the slot's, as a share.</summary>
    public const double RatioTolerance = 0.02;

    /// <summary>The file extension of a supported type; null for any other.</summary>
    public static string? Extension(string contentType) => contentType switch
    {
        Svg => "svg",
        "image/png" => "png",
        "image/webp" => "webp",
        _ => null,
    };
}

/// <summary>The body of uploadArtwork: the file, base64.</summary>
public sealed record ArtworkUpload
{
    /// <summary>image/svg+xml, image/png or image/webp.</summary>
    public required string ContentType { get; init; }
    /// <summary>The file, base64.</summary>
    public required string Data { get; init; }
}

/// <summary>The API shape of a slot on the admin page.</summary>
public sealed record ArtworkSlotView
{
    /// <summary>The key.</summary>
    public required string Key { get; init; }
    /// <summary>The app that shows it.</summary>
    public required string App { get; init; }
    /// <summary>The width in pixels.</summary>
    public required int Width { get; init; }
    /// <summary>The height in pixels.</summary>
    public required int Height { get; init; }
    /// <summary>The image; absent before seeding.</summary>
    [JsonIgnore(Condition = JsonIgnoreCondition.WhenWritingNull)]
    public string? Url { get; init; }
    /// <summary>The image type; absent before seeding.</summary>
    [JsonIgnore(Condition = JsonIgnoreCondition.WhenWritingNull)]
    public string? ContentType { get; init; }
    /// <summary>Bumped on every change; 0 without an image.</summary>
    public required int Version { get; init; }
    /// <summary>Whether an admin uploaded it.</summary>
    public required bool Replaced { get; init; }
}

/// <summary>The body of listArtwork.</summary>
public sealed record ArtworkSlotList(IReadOnlyList<ArtworkSlotView> Slots);

/// <summary>A slot's image as the apps read it.</summary>
public sealed record ArtworkImageView(string Key, string Url, int Version);

/// <summary>The body of getAppConfig.</summary>
public sealed record AppConfigView(Text Tagline, IReadOnlyList<ArtworkImageView> Artwork);

/// <summary>An admin replaced or reset an artwork slot.</summary>
public sealed record ArtworkChanged : IDomainEvent
{
    /// <summary>The name.</summary>
    public string Name { get; } = AdminEvents.ArtworkChanged;
    /// <summary>The slot key.</summary>
    public required string Key { get; init; }
    /// <summary>The image now shown; empty when the slot fell back to the bundled seed.</summary>
    public required string Url { get; init; }
    /// <summary>Whether it was reset to the seed.</summary>
    public required bool Reset { get; init; }
    /// <summary>The actor id.</summary>
    public Guid? ActorId { get; init; }
}
