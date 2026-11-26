using System.Globalization;
using System.Text.RegularExpressions;

namespace PAO.Infrastructure.Http.OpenApi;

/// <summary>
/// The string formats the contract uses, checked as ajv-formats did in "full" mode; the
/// OpenAPI numeric formats (int32, int64, double…) only describe size and always pass.
/// </summary>
public static partial class Formats
{
    /// <summary>Reports whether `text` satisfies `format`; unknown formats pass.</summary>
    public static bool IsValid(string format, string text) => format switch
    {
        "uuid" => Uuid().IsMatch(text),
        "date" => IsDate(text),
        "date-time" => IsDateTime(text),
        "email" => Email().IsMatch(text),
        _ => true,
    };

    private static bool IsDate(string text) =>
        DateOnly.TryParseExact(text, "yyyy-MM-dd", CultureInfo.InvariantCulture, DateTimeStyles.None, out _);

    private static bool IsDateTime(string text)
    {
        var parts = DateTimeSeparator().Split(text, 2);
        if (parts.Length != 2 || !IsDate(parts[0]))
        {
            return false;
        }
        var time = Time().Match(parts[1]);
        return time.Success
            && int.Parse(time.Groups[1].Value, CultureInfo.InvariantCulture) <= 23
            && int.Parse(time.Groups[2].Value, CultureInfo.InvariantCulture) <= 59
            && int.Parse(time.Groups[3].Value, CultureInfo.InvariantCulture) <= 60;
    }

    [GeneratedRegex("^(?:urn:uuid:)?[0-9a-f]{8}-(?:[0-9a-f]{4}-){3}[0-9a-f]{12}$", RegexOptions.IgnoreCase)]
    private static partial Regex Uuid();

    [GeneratedRegex("[tT ]")]
    private static partial Regex DateTimeSeparator();

    [GeneratedRegex(@"^(\d\d):(\d\d):(\d\d)(?:\.\d+)?(?:[zZ]|[+-]\d\d(?::?\d\d)?)$")]
    private static partial Regex Time();

    [GeneratedRegex(@"^[a-z0-9!#$%&'*+/=?^_`{|}~-]+(?:\.[a-z0-9!#$%&'*+/=?^_`{|}~-]+)*@(?:[a-z0-9](?:[a-z0-9-]*[a-z0-9])?\.)+[a-z0-9](?:[a-z0-9-]*[a-z0-9])?$", RegexOptions.IgnoreCase)]
    private static partial Regex Email();
}
