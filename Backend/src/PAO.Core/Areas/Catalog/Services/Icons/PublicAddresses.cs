using System.Net;
using System.Net.Sockets;

namespace PAO.Core.Areas.Catalog.Services.Icons;

/// <summary>
/// Opens connections for icon downloads only to public addresses (ADR-0039), so an admin link
/// cannot reach the database, metadata endpoints or anything else inside our network. The host
/// is resolved here and the connection goes to the address that was checked, which also defeats
/// DNS answers that change between the check and the connect.
/// </summary>
public sealed class PublicAddresses(Func<string, CancellationToken, Task<IPAddress[]>> resolve, Func<IPAddress, bool> allowed)
{
    /// <summary>Resolves with the system resolver and allows only public addresses.</summary>
    public PublicAddresses()
        : this(Dns.GetHostAddressesAsync, IsPublic)
    {
    }

    /// <summary>A stream to `endpoint`; throws <see cref="HttpRequestException"/> when any address it resolves to is not allowed.</summary>
    public async ValueTask<Stream> Connect(DnsEndPoint endpoint, CancellationToken cancellationToken)
    {
        var addresses = await resolve(endpoint.Host, cancellationToken);
        if (addresses.Length == 0 || !addresses.All(allowed))
        {
            throw new HttpRequestException($"refused: {endpoint.Host} is not a public address");
        }
        var socket = new Socket(SocketType.Stream, ProtocolType.Tcp) { NoDelay = true };
        try
        {
            await socket.ConnectAsync(new IPEndPoint(addresses[0], endpoint.Port), cancellationToken);
            return new NetworkStream(socket, ownsSocket: true);
        }
        catch
        {
            socket.Dispose();
            throw;
        }
    }

    /// <summary>Reports whether `address` is on the public internet: not loopback, private, link-local, shared, multicast or reserved.</summary>
    public static bool IsPublic(IPAddress address)
    {
        if (address.IsIPv4MappedToIPv6)
        {
            address = address.MapToIPv4();
        }
        if (address.AddressFamily == AddressFamily.InterNetwork)
        {
            var b = address.GetAddressBytes();
            return !(b[0] is 0 or 10 or 127 || b[0] >= 224
                || (b[0] == 100 && b[1] >= 64 && b[1] <= 127)
                || (b[0] == 169 && b[1] == 254)
                || (b[0] == 172 && b[1] >= 16 && b[1] <= 31)
                || (b[0] == 192 && b[1] == 0 && b[2] == 0)
                || (b[0] == 192 && b[1] == 168)
                || (b[0] == 198 && b[1] is 18 or 19));
        }
        var v6 = address.GetAddressBytes();
        return !(IPAddress.IsLoopback(address) || address.Equals(IPAddress.IPv6None)
            || address.IsIPv6LinkLocal || address.IsIPv6SiteLocal || address.IsIPv6Multicast
            || (v6[0] & 0xFE) == 0xFC
            // NAT64 can map to any IPv4 address, private ones included.
            || (v6[0] == 0x00 && v6[1] == 0x64 && v6[2] == 0xFF && v6[3] == 0x9B));
    }
}
