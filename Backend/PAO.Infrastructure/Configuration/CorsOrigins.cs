namespace PAO.Infrastructure.Configuration;

/// <summary>
/// ADMIN_CORS_ORIGIN: one origin or a comma-separated list (ADR-0036), so a preview or
/// staging admin host can call the API next to the production one.
/// </summary>
public static class CorsOrigins
{
    /// <summary>The trimmed, non-empty entries of `value`, in order.</summary>
    public static IReadOnlyList<string> Parse(string value) =>
        value.Split(',', StringSplitOptions.RemoveEmptyEntries | StringSplitOptions.TrimEntries);

    /// <summary>
    /// Whether `origin` is what a browser sends in `Origin`: an http(s) scheme and host,
    /// an optional port, and nothing else (no path, query or trailing slash).
    /// </summary>
    public static bool IsValid(string origin) =>
        Uri.TryCreate(origin, UriKind.Absolute, out var uri)
        && uri.Scheme is "http" or "https"
        && uri.UserInfo.Length == 0
        && string.Equals(uri.GetLeftPart(UriPartial.Authority), origin, StringComparison.OrdinalIgnoreCase);
}
