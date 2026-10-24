namespace PAO.Infrastructure.Data;

/// <summary>Builds LIKE patterns for the admin console's search boxes.</summary>
public static class SqlLike
{
    /// <summary>
    /// "Contains" for the trimmed, lower-cased `text`, with `\`, `%` and `_` escaped so they
    /// match literally; empty for empty text, which the queries read as "no filter".
    /// </summary>
    public static string Contains(string text)
    {
        var t = text.Trim().ToLowerInvariant();
        return t.Length == 0 ? string.Empty : $"%{t.Replace("\\", "\\\\").Replace("%", "\\%").Replace("_", "\\_")}%";
    }
}
