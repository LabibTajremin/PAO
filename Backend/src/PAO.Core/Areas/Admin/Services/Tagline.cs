using System.Text.Json;
using PAO.Lib.Areas.Admin;
using PAO.Lib.Common;

namespace PAO.Core.Areas.Admin.Services;

/// <summary>The brand tagline setting (06-update §6): English and Bangla, 40 characters each.</summary>
public static class Tagline
{
    /// <summary>The setting key.</summary>
    public const string Key = "brand.tagline";

    /// <summary>The setting type that holds a tagline.</summary>
    public const string Type = "tagline";

    /// <summary>The most characters per language.</summary>
    public const int MaxLength = 40;

    /// <summary>The seed tagline, also used when the stored one cannot be read.</summary>
    public static readonly Text Default = new() { En = "Ask for it. PAO it.", Bn = "যা চাও, তাই PAO" };

    /// <summary>The tagline in `json`; null unless both languages are present, not blank and short enough.</summary>
    public static Text? Parse(string json)
    {
        try
        {
            var text = JsonSerializer.Deserialize<Text>(json, JsonSerializerOptions.Web);
            return text is not null && Fits(text.En) && Fits(text.Bn) ? text : null;
        }
        catch (JsonException)
        {
            return null;
        }
    }

    /// <summary>The stored tagline, or <see cref="Default"/>.</summary>
    public static Text Read(IReadOnlyDictionary<string, string> settings) =>
        settings.TryGetValue(Key, out var json) && Parse(json) is { } text ? text : Default;

    private static bool Fits(string? value) => value is not null && AdminText.Length(value) is > 0 and <= MaxLength;
}
