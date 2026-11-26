using System.Buffers.Binary;
using System.Text;

namespace PAO.Infrastructure.Images;

/// <summary>A raster image's size and whether it can be transparent.</summary>
public readonly record struct ImageHeader(int Width, int Height, bool HasAlpha);

/// <summary>
/// Reads the size and alpha of a PNG or WebP from its header, without decoding the image, so
/// uploads can be checked cheaply before they are stored.
/// </summary>
public static class ImageHeaders
{
    /// <summary>The `"image/png"` value.</summary>
    public const string Png = "image/png";

    /// <summary>The `"image/webp"` value.</summary>
    public const string Webp = "image/webp";

    /// <summary>The header of a PNG or WebP; null when the file is not the stated type.</summary>
    public static ImageHeader? Read(string contentType, byte[] file) =>
        contentType == Png ? ReadPng(file) : ReadWebp(file);

    /// <summary>The PNG header; null when the file is not a PNG.</summary>
    public static ImageHeader? ReadPng(byte[] file)
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
        return new ImageHeader(width, height, alpha);
    }

    /// <summary>The WebP header; null when the file is not a WebP.</summary>
    public static ImageHeader? ReadWebp(byte[] file)
    {
        if (file.Length < 30 || Tag(file, 0) != "RIFF" || Tag(file, 8) != "WEBP")
        {
            return null;
        }
        return Tag(file, 12) switch
        {
            "VP8X" => new ImageHeader(Int24(file, 24) + 1, Int24(file, 27) + 1, (file[20] & 0x10) != 0),
            "VP8L" when file[20] == 0x2F => Lossless(BinaryPrimitives.ReadUInt32LittleEndian(file.AsSpan(21))),
            // Simple lossy WebP has no alpha channel.
            "VP8 " => new ImageHeader(BinaryPrimitives.ReadUInt16LittleEndian(file.AsSpan(26)) & 0x3FFF, BinaryPrimitives.ReadUInt16LittleEndian(file.AsSpan(28)) & 0x3FFF, false),
            _ => null,
        };
    }

    private static ImageHeader Lossless(uint bits) =>
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
