using System.Globalization;
using System.Text.RegularExpressions;
using Npgsql;

namespace PAO.EF.Connection;

/// <summary>
/// Turns DATABASE_URL (`postgres://user:pass@host:5432/db?sslmode=disable`) into an Npgsql
/// connection string. Pool sizing follows the NestJS backend, which followed pgxpool:
/// `pool_max_conns` (default max(4, CPUs)), `pool_max_conn_lifetime` (1h),
/// `pool_max_conn_idle_time` (30m) and `connect_timeout` in seconds.
/// </summary>
public static partial class PostgresUrl
{
    /// <summary>Returns the Npgsql connection string for `url`; throws on anything else.</summary>
    public static string ToConnectionString(string url)
    {
        if (!Uri.TryCreate(url, UriKind.Absolute, out var uri) || uri.Scheme is not ("postgres" or "postgresql"))
        {
            throw new FormatException("DATABASE_URL must be a postgres:// URL");
        }
        var query = ParseQuery(uri.Query);
        var builder = new NpgsqlConnectionStringBuilder
        {
            Host = uri.Host,
            Port = uri.IsDefaultPort ? 5432 : uri.Port,
            Database = Uri.UnescapeDataString(uri.AbsolutePath.TrimStart('/')),
            MaxPoolSize = PositiveInt(query, "pool_max_conns") ?? Math.Max(4, Environment.ProcessorCount),
            ConnectionLifetime = Seconds(query, "pool_max_conn_lifetime") ?? 3600,
            ConnectionIdleLifetime = Seconds(query, "pool_max_conn_idle_time") ?? 1800,
            // The runtime image has no Kerberos library; probing for it logs an error on every start.
            GssEncryptionMode = GssEncryptionMode.Disable,
        };
        AddCredentials(builder, uri.UserInfo);
        if (PositiveInt(query, "connect_timeout") is { } timeout)
        {
            builder.Timeout = timeout;
        }
        if (query.TryGetValue("sslmode", out var ssl))
        {
            builder.SslMode = SslModeOf(ssl);
        }
        return builder.ConnectionString;
    }

    /// <summary>Parses a Go duration such as `1h30m` or `90s` into milliseconds; null if invalid.</summary>
    public static double? ParseGoDuration(string text)
    {
        if (!GoDuration().IsMatch(text))
        {
            return null;
        }
        double total = 0;
        foreach (Match part in DurationPart().Matches(text))
        {
            var amount = double.Parse(part.Groups[1].Value, CultureInfo.InvariantCulture);
            total += amount * part.Groups[2].Value switch
            {
                "ms" => 1,
                "s" => 1000,
                "m" => 60_000,
                _ => 3_600_000,
            };
        }
        return total;
    }

    private static void AddCredentials(NpgsqlConnectionStringBuilder builder, string userInfo)
    {
        if (userInfo.Length == 0)
        {
            return;
        }
        var colon = userInfo.IndexOf(':', StringComparison.Ordinal);
        builder.Username = Uri.UnescapeDataString(colon < 0 ? userInfo : userInfo[..colon]);
        if (colon >= 0)
        {
            builder.Password = Uri.UnescapeDataString(userInfo[(colon + 1)..]);
        }
    }

    private static Dictionary<string, string> ParseQuery(string query)
    {
        var values = new Dictionary<string, string>(StringComparer.Ordinal);
        foreach (var pair in query.TrimStart('?').Split('&', StringSplitOptions.RemoveEmptyEntries))
        {
            var eq = pair.IndexOf('=', StringComparison.Ordinal);
            var key = Uri.UnescapeDataString(eq < 0 ? pair : pair[..eq]);
            values[key] = eq < 0 ? string.Empty : Uri.UnescapeDataString(pair[(eq + 1)..]);
        }
        return values;
    }

    private static int? PositiveInt(Dictionary<string, string> query, string key) =>
        query.TryGetValue(key, out var text) && int.TryParse(text, NumberStyles.None, CultureInfo.InvariantCulture, out var n) && n > 0
            ? n
            : null;

    private static int? Seconds(Dictionary<string, string> query, string key) =>
        query.TryGetValue(key, out var text) && ParseGoDuration(text) is { } ms ? (int)Math.Ceiling(ms / 1000) : null;

    private static SslMode SslModeOf(string mode) => mode switch
    {
        "disable" => SslMode.Disable,
        "allow" => SslMode.Allow,
        "prefer" => SslMode.Prefer,
        "require" => SslMode.Require,
        "verify-ca" => SslMode.VerifyCA,
        "verify-full" => SslMode.VerifyFull,
        _ => throw new FormatException($"DATABASE_URL has an unknown sslmode \"{mode}\""),
    };

    [GeneratedRegex(@"^(?:\d+(?:\.\d+)?(?:ms|s|m|h))+$")]
    private static partial Regex GoDuration();

    [GeneratedRegex(@"(\d+(?:\.\d+)?)(ms|s|m|h)")]
    private static partial Regex DurationPart();
}
