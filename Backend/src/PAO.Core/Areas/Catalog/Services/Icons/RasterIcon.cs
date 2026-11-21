using System.Buffers.Binary;
using System.Text;
using PAO.Lib.Areas.Catalog;
using PAO.Lib.Errors;

namespace PAO.Core.Areas.Catalog.Services.Icons;

/// <summary>
/// Reads the size and alpha of a PNG or WebP icon from its header, without decoding it, and
/// enforces the icon rules: square, at least <see cref="IconTypes.MinRasterSide"/> pixels a
/// side, with transparency (ADR-0039).
/// </summary>
public static class RasterIcon
{
    /// <summary>What the header says.</summary>
    public readonly record struct Header(int Width, int Height, bool HasAlpha);

    /// <summary>Throws the reason the icon breaks a rule, if any.</summary>
    public static void Check(string contentType, byte[] file)
    {
        var header = (contentType == IconTypes.Png ? ReadPng(file) : ReadWebp(file))
            ?? throw new DomainException(CatalogReasons.IconUnreadable);
        CatalogChanges.Check(header.Width == header.Height, CatalogReasons.IconNotSquare);
        CatalogChanges.Check(header.Width >= IconTypes.MinRasterSide, CatalogReasons.IconTooSmall);
        CatalogChanges.Check(header.HasAlpha, CatalogReasons.IconOpaque);
    }

    /// <summary>The PNG header; null when the file is not a PNG.</summary>
    public static Header? ReadPng(byte[] file)
    {
        ReadOnlySpan<byte> signature = [0x89, 0x50, 0x4E, 0x47, 0x0D, 0x0A, 0x1A, 0x0A];
        if (file.Length < 33 || !file.AsSpan(0, 8).SequenceEqual(signature) || Tag(file, 12) != "IHDR")
        {
            return null;
        }
        var width = BinaryPrimitives.ReadInt32BigEndian(file.AsSpan(16));
        var height = BinaryPrimitives.ReadInt32BigEndian(file.AsSpan(20));
        // Colour types 4 and 6 carry an alpha channel; any other has alpha only through tRNS.
        var alpha = file[25] is 4 or 6 || HasPngChunk(file, "tRNS");
        return new Header(width, height, alpha);
    }

    /// <summary>The WebP header; null when the file is not a WebP.</summary>
    public static Header? ReadWebp(byte[] file)
    {
        if (file.Length < 30 || Tag(file, 0) != "RIFF" || Tag(file, 8) != "WEBP")
        {
            return null;
        }
        return Tag(file, 12) switch
        {
            "VP8X" => new Header(Int24(file, 24) + 1, Int24(file, 27) + 1, (file[20] & 0x10) != 0),
            "VP8L" when file[20] == 0x2F => Lossless(BinaryPrimitives.ReadUInt32LittleEndian(file.AsSpan(21))),
            // Simple lossy WebP has no alpha channel.
            "VP8 " => new Header(BinaryPrimitives.ReadUInt16LittleEndian(file.AsSpan(26)) & 0x3FFF, BinaryPrimitives.ReadUInt16LittleEndian(file.AsSpan(28)) & 0x3FFF, false),
            _ => null,
        };
    }

    private static Header Lossless(uint bits) =>
        new((int)(bits & 0x3FFF) + 1, (int)((bits >> 14) & 0x3FFF) + 1, ((bits >> 28) & 1) == 1);

    private static bool HasPngChunk(byte[] file, string type)
    {
        for (var at = 8; at + 8 <= file.Length;)
        {
            var length = BinaryPrimitives.ReadInt32BigEndian(file.AsSpan(at));
            var tag = Tag(file, at + 4);
            if (tag == type)
            {
                return true;
            }
            if (tag is "IDAT" or "IEND" || length < 0 || length > file.Length)
            {
                return false;
            }
            at += 12 + length;
        }
        return false;
    }

    private static string Tag(byte[] file, int at) => Encoding.ASCII.GetString(file, at, 4);

    private static int Int24(byte[] file, int at) => file[at] | (file[at + 1] << 8) | (file[at + 2] << 16);
}
