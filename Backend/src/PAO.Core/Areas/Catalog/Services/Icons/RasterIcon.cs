using PAO.Infrastructure.Images;
using PAO.Lib.Areas.Catalog;
using PAO.Lib.Errors;

namespace PAO.Core.Areas.Catalog.Services.Icons;

/// <summary>
/// The icon rules for PNG and WebP (ADR-0039): square, at least
/// <see cref="IconTypes.MinRasterSide"/> pixels a side, with transparency.
/// </summary>
public static class RasterIcon
{
    /// <summary>Throws the reason the icon breaks a rule, if any.</summary>
    public static void Check(string contentType, byte[] file)
    {
        var header = ImageHeaders.Read(contentType, file) ?? throw new DomainException(CatalogReasons.IconUnreadable);
        CatalogChanges.Check(header.Width == header.Height, CatalogReasons.IconNotSquare);
        CatalogChanges.Check(header.Width >= IconTypes.MinRasterSide, CatalogReasons.IconTooSmall);
        CatalogChanges.Check(header.HasAlpha, CatalogReasons.IconOpaque);
    }
}
