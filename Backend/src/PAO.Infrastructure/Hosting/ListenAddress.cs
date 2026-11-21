using System.Globalization;
using System.Text.RegularExpressions;

namespace PAO.Infrastructure.Hosting;

/// <summary>A TCP listen address in Go's `host:port` form; `:8080` means every interface.</summary>
public sealed partial record ListenAddress(string? Host, int Port)
{
    /// <summary>Parses `:8080`, `127.0.0.1:0` or `[::1]:9090`; throws on anything else.</summary>
    public static ListenAddress Parse(string address)
    {
        var match = Pattern().Match(address);
        if (!match.Success || !int.TryParse(match.Groups[3].Value, NumberStyles.None, CultureInfo.InvariantCulture, out var port) || port > 65535)
        {
            throw new FormatException($"invalid listen address \"{address}\"");
        }
        var host = match.Groups[1].Success ? match.Groups[1].Value : match.Groups[2].Value;
        return new ListenAddress(host.Length == 0 ? null : host, port);
    }

    /// <summary>Reports whether `address` parses.</summary>
    public static bool IsValid(string address)
    {
        try
        {
            Parse(address);
            return true;
        }
        catch (FormatException)
        {
            return false;
        }
    }

    /// <summary>The Kestrel URL, e.g. `http://0.0.0.0:8080`.</summary>
    public string ToUrl()
    {
        var host = Host ?? "0.0.0.0";
        return $"http://{(host.Contains(':', StringComparison.Ordinal) ? $"[{host}]" : host)}:{Port}";
    }

    [GeneratedRegex(@"^(?:\[([^\]]+)\]|([^:]*)):(\d{1,5})$")]
    private static partial Regex Pattern();
}
