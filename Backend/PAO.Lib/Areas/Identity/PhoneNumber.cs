using System.Text.RegularExpressions;

namespace PAO.Lib.Areas.Identity;

/// <summary>Bangladeshi mobile numbers as the Identity area stores them.</summary>
public static partial class PhoneNumber
{
    /// <summary>
    /// Accepts the common ways people type a Bangladeshi mobile number (01712…, 8801712…,
    /// +880 1712-…) and returns its E.164 form, or null when it is not one.
    /// </summary>
    public static string? Normalize(string raw)
    {
        var match = BdMobile().Match(Separators().Replace(raw.Trim(), string.Empty));
        return match.Success ? "+880" + match.Groups[1].Value : null;
    }

    /// <summary>Hides all but the last three digits, for logs and messages.</summary>
    public static string Mask(string phone) => phone.Length < 3 ? "***" : new string('*', phone.Length - 3) + phone[^3..];

    [GeneratedRegex(@"^(?:\+?880|0)?(1[3-9][0-9]{8})$")]
    private static partial Regex BdMobile();

    [GeneratedRegex("[ ()-]")]
    private static partial Regex Separators();
}
