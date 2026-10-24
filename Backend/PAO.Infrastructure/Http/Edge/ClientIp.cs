using System.Net;

namespace PAO.Infrastructure.Http.Edge;

/// <summary>
/// Finds the client address. X-Forwarded-For is trusted only when the connection comes from
/// a private address (our load balancer), and then only its rightmost entry, the one the
/// load balancer appended, so clients cannot spoof their address for rate limits.
/// </summary>
public static class ClientIp
{
    private static readonly (IPAddress Network, int Prefix)[] PrivateNetworks =
    [
        (IPAddress.Parse("10.0.0.0"), 8),
        (IPAddress.Parse("172.16.0.0"), 12),
        (IPAddress.Parse("192.168.0.0"), 16),
        (IPAddress.Parse("127.0.0.0"), 8),
        (IPAddress.Parse("::1"), 128),
        (IPAddress.Parse("fc00::"), 7),
    ];

    /// <summary>Writes an IPv4-mapped IPv6 address (`::ffff:10.0.0.5`) as plain IPv4.</summary>
    public static string Normalize(IPAddress? address) =>
        address is null ? string.Empty : (address.IsIPv4MappedToIPv6 ? address.MapToIPv4() : address).ToString();

    /// <summary>Reports whether `ip` belongs to a private network (our load balancer).</summary>
    public static bool IsPrivate(string ip) =>
        IPAddress.TryParse(ip, out var address) && PrivateNetworks.Any(n => n.Network.AddressFamily == address.AddressFamily && InNetwork(address, n.Network, n.Prefix));

    /// <summary>Returns the client address for a connection from `peer` with `forwardedFor` headers.</summary>
    public static string Resolve(string peer, IReadOnlyList<string> forwardedFor)
    {
        if (forwardedFor.Count == 0 || !IsPrivate(peer))
        {
            return peer;
        }
        var last = forwardedFor[^1].Split(',')[^1].Trim();
        return IPAddress.TryParse(last, out var address) ? Normalize(address) : peer;
    }

    private static bool InNetwork(IPAddress address, IPAddress network, int prefix)
    {
        var a = address.GetAddressBytes();
        var n = network.GetAddressBytes();
        var whole = prefix / 8;
        if (!a.AsSpan(0, whole).SequenceEqual(n.AsSpan(0, whole)))
        {
            return false;
        }
        var bits = prefix % 8;
        var mask = (byte)(0xFF << (8 - bits));
        return bits == 0 || (a[whole] & mask) == (n[whole] & mask);
    }
}
