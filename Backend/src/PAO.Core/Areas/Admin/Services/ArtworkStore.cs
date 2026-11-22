using PAO.Infrastructure.Configuration;
using PAO.Infrastructure.Data;
using PAO.Infrastructure.Images;
using PAO.Infrastructure.Storage;
using PAO.Lib.Areas.Admin;
using PAO.Lib.Errors;

namespace PAO.Core.Areas.Admin.Services;

/// <summary>
/// Checks artwork against its slot (06-update §5) and stores it in the public bucket under
/// `artwork/&lt;slot&gt;/`, where the apps read it (ADR-0040).
/// </summary>
public sealed class ArtworkStore(ObjectStore store, PaoSettings settings, IIdGenerator ids)
{
    /// <summary>The file to store: the sanitised SVG, or the PNG or WebP as uploaded; throws why it does not fit.</summary>
    public static byte[] Checked(ArtworkSpec slot, string contentType, byte[] file)
    {
        _ = ArtworkFiles.Extension(contentType) ?? throw new DomainException(AdminReasons.ArtworkUnreadable);
        var svg = contentType == ArtworkFiles.Svg;
        Require(file.Length <= (svg ? ArtworkFiles.MaxSvgBytes : ArtworkFiles.MaxRasterBytes), AdminReasons.ArtworkTooLarge);
        return svg ? CheckedSvg(slot, file) : CheckedRaster(slot, contentType, file);
    }

    /// <summary>Stores a checked file under a new name and returns the URL devices read it from.</summary>
    public async Task<string> Put(string slotKey, string contentType, byte[] file, CancellationToken cancellationToken) =>
        await PutAs(slotKey, $"{ids.NewId():N}.{ArtworkFiles.Extension(contentType)}", contentType, file, cancellationToken);

    /// <summary>Stores a checked file under `name`, replacing one of that name, and returns its URL.</summary>
    public async Task<string> PutAs(string slotKey, string name, string contentType, byte[] file, CancellationToken cancellationToken)
    {
        var key = $"{ObjectStore.ArtworkFolder}/{slotKey}/{name}";
        using (var content = new MemoryStream(file))
        {
            await store.Put(settings.Storage.BucketPublic, key, contentType, content, cancellationToken);
        }
        return $"{ObjectStore.PublicBase(settings.Storage)}/{key}";
    }

    private static byte[] CheckedSvg(ArtworkSpec slot, byte[] file)
    {
        try
        {
            var clean = SvgSanitizer.Clean(file);
            var ratio = SvgSanitizer.AspectRatio(clean) ?? throw new DomainException(AdminReasons.ArtworkUnreadable);
            if (Math.Abs((ratio / ((double)slot.Width / slot.Height)) - 1) > ArtworkFiles.RatioTolerance)
            {
                throw WrongSize(slot);
            }
            return clean;
        }
        catch (ImageFormatException error)
        {
            throw new DomainException(AdminReasons.ArtworkUnreadable, error);
        }
    }

    private static byte[] CheckedRaster(ArtworkSpec slot, string contentType, byte[] file)
    {
        var header = ImageHeaders.Read(contentType, file) ?? throw new DomainException(AdminReasons.ArtworkUnreadable);
        if (header.Width != slot.Width || header.Height != slot.Height)
        {
            throw WrongSize(slot);
        }
        Require(header.HasAlpha, AdminReasons.ArtworkOpaque);
        return file;
    }

    private static DomainException WrongSize(ArtworkSpec slot) => new(AdminReasons.ArtworkWrongSize)
    {
        Details = new Dictionary<string, object?> { ["expected"] = $"{slot.Width}x{slot.Height}" },
    };

    private static void Require(bool ok, string reason)
    {
        if (!ok)
        {
            throw new DomainException(reason);
        }
    }
}
