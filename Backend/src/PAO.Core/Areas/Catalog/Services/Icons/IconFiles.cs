using PAO.Core.Areas.Catalog.Repositories;
using PAO.Infrastructure.Configuration;
using PAO.Infrastructure.Data;
using PAO.Infrastructure.Images;
using PAO.Infrastructure.Storage;
using PAO.Lib.Areas.Catalog;
using PAO.Lib.Errors;

namespace PAO.Core.Areas.Catalog.Services.Icons;

/// <summary>
/// Checks an icon file against its type's rules, stores the cleaned file in the public bucket
/// under a new name and announces it with `IconAdded`, which the audit log records (ADR-0039).
/// </summary>
public sealed class IconFiles(ObjectStore store, PaoSettings settings, IconAddress address, CatalogWriteRepository writer, IIdGenerator ids)
{
    /// <summary>Stores `file` and returns where devices read it.</summary>
    public async Task<CatalogIconView> Store(string contentType, byte[] file, string? sourceUrl, Guid actorId, CancellationToken cancellationToken)
    {
        var extension = IconTypes.Extension(contentType) ?? throw new DomainException(CatalogReasons.IconUnreadable);
        CatalogChanges.Check(file.Length <= IconTypes.MaxBytes(contentType), CatalogReasons.IconTooLarge);
        var clean = Checked(contentType, file);
        var name = $"{ids.NewId():N}.{extension}";
        using (var content = new MemoryStream(clean))
        {
            await store.Put(settings.Storage.BucketPublic, IconAddress.KeyOf(name), contentType, content, cancellationToken);
        }
        var url = address.UrlOf(name);
        await writer.Publish(name, new IconAdded { IconUrl = url, ContentType = contentType, SourceUrl = sourceUrl, ActorId = actorId }, cancellationToken);
        return new CatalogIconView { IconUrl = url, ContentType = contentType };
    }

    private static byte[] Checked(string contentType, byte[] file)
    {
        if (contentType == IconTypes.Svg)
        {
            try
            {
                return SvgSanitizer.Clean(file);
            }
            catch (ImageFormatException error)
            {
                throw new DomainException(CatalogReasons.IconUnreadable, error);
            }
        }
        RasterIcon.Check(contentType, file);
        return file;
    }
}
