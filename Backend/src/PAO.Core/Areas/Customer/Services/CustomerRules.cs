using PAO.Lib.Areas.Customer;
using PAO.Lib.Common;
using PAO.Lib.Errors;

namespace PAO.Core.Areas.Customer.Services;

/// <summary>The profile and address rules (C-01, C-02).</summary>
public static class CustomerRules
{
    /// <summary>Saved addresses per customer.</summary>
    public const int MaxAddresses = 10;

    /// <summary>Address labels the app offers.</summary>
    public static readonly IReadOnlyList<string> AddressLabels = ["home", "office", "other"];

    /// <summary>Counts code points, as Go counted runes, so Bangla text gets the same limits.</summary>
    public static int Length(string s) => s.EnumerateRunes().Count();

    /// <summary>Checks the profile fields; null when they are fine.</summary>
    public static string? ProfileProblem(string name, string language)
    {
        var n = Length(name.Trim());
        return n < 2 || n > 80 || language is not (Language.English or Language.Bangla) ? CustomerReasons.Invalid : null;
    }

    /// <summary>Checks the address fields and that the pin lies in Bangladesh; null when fine.</summary>
    public static string? AddressProblem(string label, string line1, string line2, string area, GeoPoint location)
    {
        var first = Length(line1.Trim());
        if (!AddressLabels.Contains(label) || first < 3 || first > 200 || Length(line2) > 200 || Length(area) > 80)
        {
            return CustomerReasons.Invalid;
        }
        return InBangladesh(location) ? null : CustomerReasons.OutsideCountry;
    }

    /// <summary>
    /// A bounding-box check: it rejects pins dropped far away (a wrong sign or swapped
    /// coordinates) without needing the exact border.
    /// </summary>
    public static bool InBangladesh(GeoPoint p) => p.Lat is >= 20.5 and <= 26.7 && p.Lng is >= 88.0 and <= 92.7;

    /// <summary>Throws the domain error for `problem`, if any.</summary>
    public static void Check(string? problem)
    {
        if (problem is not null)
        {
            throw new DomainException(problem);
        }
    }
}
