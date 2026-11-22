using System.Text.RegularExpressions;
using PAO.Infrastructure.Configuration;
using PAO.Infrastructure.Storage;

namespace PAO.Core.Areas.Catalog.Services;

/// <summary>
/// Where stored catalog icons live in the public bucket and the URLs devices read them from
/// (ADR-0039). A category or service only takes an icon URL that points there, so the apps
/// never load an icon from someone else's site.
/// </summary>
public sealed partial class IconAddress(PaoSettings settings)
{
    /// <summary>The folder of the public bucket that holds catalog icons, and the only readable one.</summary>
    public const string Folder = ObjectStore.IconFolder;

    /// <summary>The URL prefix every stored icon starts with, ending in a slash.</summary>
    public string Base => $"{ObjectStore.PublicBase(settings.Storage)}/{Folder}/";

    /// <summary>The object key of a stored icon file.</summary>
    public static string KeyOf(string fileName) => $"{Folder}/{fileName}";

    /// <summary>The URL devices read a stored icon file from.</summary>
    public string UrlOf(string fileName) => Base + fileName;

    /// <summary>Reports whether `url` is absent or names an icon file we stored.</summary>
    public bool IsStoredOrAbsent(string? url) =>
        url is null || (url.StartsWith(Base, StringComparison.Ordinal) && FileName().IsMatch(url[Base.Length..]));

    [GeneratedRegex("^[0-9a-f]{32}\\.(svg|png|webp)$")]
    private static partial Regex FileName();
}
