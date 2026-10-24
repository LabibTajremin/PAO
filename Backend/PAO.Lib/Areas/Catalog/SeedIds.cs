using System.Security.Cryptography;
using System.Text;

namespace PAO.Lib.Areas.Catalog;

/// <summary>
/// Stable ids derived from seed keys, so reseeding updates rows instead of duplicating
/// them. UUIDv5 in the namespace the Go and NestJS backends used, so all derive the same ids.
/// </summary>
public static class SeedIds
{
    private static readonly Guid Namespace = Guid.Parse("6b1f3c7e-2f4a-5d8e-9a0b-1c2d3e4f5a6b");

    /// <summary>The id of a seeded `category`, `service` or `sub-service` with `key`.</summary>
    public static Guid For(string kind, string key) => UuidV5(Namespace, $"{kind}/{key}");

    /// <summary>RFC 4122 name-based UUID, version 5 (SHA-1).</summary>
    public static Guid UuidV5(Guid ns, string name)
    {
        var nsBytes = ns.ToByteArray(bigEndian: true);
        var nameBytes = Encoding.UTF8.GetBytes(name);
#pragma warning disable CA5350 // UUIDv5 is defined over SHA-1; it is an identifier, not a security hash.
        var hash = SHA1.HashData([.. nsBytes, .. nameBytes]);
#pragma warning restore CA5350
        var bytes = hash[..16];
        bytes[6] = (byte)((bytes[6] & 0x0F) | 0x50);
        bytes[8] = (byte)((bytes[8] & 0x3F) | 0x80);
        return new Guid(bytes, bigEndian: true);
    }
}
