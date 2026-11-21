using System.Text.RegularExpressions;

namespace PAO.Infrastructure.Configuration;

/// <summary>Decodes standard, padded base64 strictly, so malformed keys fail at start.</summary>
public static partial class StrictBase64
{
    /// <summary>Returns the bytes of `value`, or null for anything that is not strict base64.</summary>
    public static byte[]? Decode(string value) => Strict().IsMatch(value) ? Convert.FromBase64String(value) : null;

    [GeneratedRegex("^(?:[A-Za-z0-9+/]{4})*(?:[A-Za-z0-9+/]{2}==|[A-Za-z0-9+/]{3}=)?$")]
    private static partial Regex Strict();
}
