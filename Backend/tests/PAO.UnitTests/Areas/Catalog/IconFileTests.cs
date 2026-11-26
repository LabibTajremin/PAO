using System.Buffers.Binary;
using System.Text;
using PAO.Core.Areas.Catalog.Features.Icons.Commands;
using PAO.Core.Areas.Catalog.Features.Icons.Queries;
using PAO.Core.Areas.Catalog.Services;
using PAO.Core.Areas.Catalog.Services.Icons;
using PAO.Infrastructure.Hosting;
using PAO.Infrastructure.Images;
using PAO.Lib.Areas.Catalog;
using PAO.Lib.Errors;
using PAO.TestKit;

namespace PAO.UnitTests.Areas.Catalog;

public sealed class IconFileTests
{
    internal static string Reason(Action act) => Assert.Throws<DomainException>(act).Reason;

    internal static byte[] Png(int width, int height, byte colourType, string? chunk = null)
    {
        var file = new List<byte> { 0x89, 0x50, 0x4E, 0x47, 0x0D, 0x0A, 0x1A, 0x0A };
        void Chunk(string type, byte[] data)
        {
            var length = new byte[4];
            BinaryPrimitives.WriteInt32BigEndian(length, data.Length);
            file.AddRange(length);
            file.AddRange(Encoding.ASCII.GetBytes(type));
            file.AddRange(data);
            file.AddRange(new byte[4]);
        }
        var header = new byte[13];
        BinaryPrimitives.WriteInt32BigEndian(header, width);
        BinaryPrimitives.WriteInt32BigEndian(header.AsSpan(4), height);
        header[8] = 8;
        header[9] = colourType;
        Chunk("IHDR", header);
        if (chunk is not null)
        {
            Chunk(chunk, [0, 0]);
        }
        Chunk("IDAT", [1, 2, 3]);
        Chunk("tRNS", [0, 0]);
        Chunk("IEND", []);
        return [.. file];
    }

    internal static byte[] Webp(string chunk, Action<byte[]> fill)
    {
        var file = new byte[40];
        Encoding.ASCII.GetBytes("RIFF").CopyTo(file, 0);
        Encoding.ASCII.GetBytes("WEBP").CopyTo(file, 8);
        Encoding.ASCII.GetBytes(chunk).CopyTo(file, 12);
        fill(file);
        return file;
    }

    internal static byte[] Lossless(int width, int height, bool alpha) => Webp("VP8L", f =>
    {
        f[20] = 0x2F;
        BinaryPrimitives.WriteUInt32LittleEndian(f.AsSpan(21), (uint)(width - 1) | ((uint)(height - 1) << 14) | (alpha ? 1u << 28 : 0));
    });

    [Fact]
    public void Icon_urls_start_with_the_public_base_and_name_a_stored_file()
    {
        var settings = TestSettings.Create();
        settings.Storage.Endpoint = "http://minio:9000";
        var address = new IconAddress(settings);
        Assert.Equal("http://minio:9000/pao-net-test-public/catalog-icons/", address.Base);
        settings.Storage.PublicEndpoint = "https://files.pao.example/";
        Assert.Equal("https://files.pao.example/pao-net-test-public/catalog-icons/", address.Base);
        settings.Storage.PublicBaseUrl = "https://cdn.pao.example/";
        var name = $"{Guid.NewGuid():N}.svg";
        Assert.Equal($"https://cdn.pao.example/catalog-icons/{name}", address.UrlOf(name));
        Assert.Equal($"catalog-icons/{name}", IconAddress.KeyOf(name));
        Assert.True(address.IsStoredOrAbsent(null));
        Assert.True(address.IsStoredOrAbsent(address.UrlOf(name)));
        Assert.False(address.IsStoredOrAbsent($"https://evil.example/catalog-icons/{name}"));
        Assert.False(address.IsStoredOrAbsent(address.UrlOf("x.svg")));
        Assert.False(address.IsStoredOrAbsent(address.UrlOf($"{Guid.NewGuid():N}.gif")));
    }

    [Fact]
    public void Svg_keeps_drawing_and_drops_everything_active_or_external()
    {
        const string svg = """
            <svg xmlns="http://www.w3.org/2000/svg" xmlns:xlink="http://www.w3.org/1999/xlink" xmlns:inkscape="http://www.inkscape.org/namespaces/inkscape" viewBox="0 0 24 24" onload="alert(1)" inkscape:version="1">
              <!-- editor note -->
              <title>Tap</title>
              <script>alert(1)</script>
              <foreignObject><div xmlns="http://www.w3.org/1999/xhtml">x</div></foreignObject>
              <image href="https://evil.example/x.png"/>
              <inkscape:grid/>
              <defs><linearGradient id="g"><stop offset="0" stop-color="#000"/></linearGradient></defs>
              <path d="M0 0h24" fill="url(#g)" style="stroke: url( '#g' )" onclick="x()"/>
              <use href="#g" xlink:href="https://evil.example/a.svg#x"/>
              <rect width="2" height="2" style="fill: url(https://evil.example/a)"/>
              <circle r="1" fill="javascript:alert(1)"/>
            </svg>
            """;
        var clean = Encoding.UTF8.GetString(SvgSanitizer.Clean(Encoding.UTF8.GetBytes(svg)));
        foreach (var gone in new[] { "onload", "script", "foreignObject", "image", "inkscape", "editor note", "onclick", "evil.example", "javascript" })
        {
            Assert.DoesNotContain(gone, clean, StringComparison.OrdinalIgnoreCase);
        }
        foreach (var kept in new[] { "<title>Tap</title>", "d=\"M0 0h24\"", "fill=\"url(#g)\"", "href=\"#g\"", "stop-color", "<rect width=\"2\" height=\"2\"", "<circle r=\"1\"" })
        {
            Assert.Contains(kept, clean);
        }
    }

    [Theory]
    [InlineData("<html/>")]
    [InlineData("<svg xmlns='http://www.w3.org/2000/svg'>")]
    [InlineData("<!DOCTYPE svg [<!ENTITY x 'y'>]><svg xmlns='http://www.w3.org/2000/svg'>&x;</svg>")]
    [InlineData("<svg/>")]
    public void Svg_that_is_not_a_well_formed_svg_document_is_refused(string text) =>
        Assert.Throws<ImageFormatException>(() => SvgSanitizer.Clean(Encoding.UTF8.GetBytes(text)));

    [Theory]
    [InlineData("<svg xmlns='http://www.w3.org/2000/svg' viewBox='0 0 1170 1200'/>", 0.975)]
    [InlineData("<svg xmlns='http://www.w3.org/2000/svg' viewBox='0,0,720,540' width='10' height='10'/>", 1.3333)]
    [InlineData("<svg xmlns='http://www.w3.org/2000/svg' width='720px' height='720'/>", 1.0)]
    [InlineData("<svg xmlns='http://www.w3.org/2000/svg' viewBox='0 0 10'/>", null)]
    [InlineData("<svg xmlns='http://www.w3.org/2000/svg' width='auto' height='5'/>", null)]
    public void Svg_ratio_comes_from_the_view_box_or_the_size(string text, double? ratio)
    {
        var found = SvgSanitizer.AspectRatio(Encoding.UTF8.GetBytes(text));
        Assert.Equal(ratio is null, found is null);
        Assert.Equal(ratio ?? 0, found ?? 0, 3);
    }

    [Fact]
    public void Png_and_webp_icons_must_be_square_large_enough_and_transparent()
    {
        RasterIcon.Check(IconTypes.Png, Png(96, 96, 6));
        RasterIcon.Check(IconTypes.Png, Png(128, 128, 4));
        RasterIcon.Check(IconTypes.Png, Png(96, 96, 3, "tRNS"));
        RasterIcon.Check(IconTypes.Webp, Lossless(200, 200, true));
        RasterIcon.Check(IconTypes.Webp, Webp("VP8X", f =>
        {
            f[20] = 0x10;
            f[24] = 95;
            f[27] = 95;
        }));
        Assert.Equal(CatalogReasons.IconNotSquare, Reason(() => RasterIcon.Check(IconTypes.Png, Png(96, 120, 6))));
        Assert.Equal(CatalogReasons.IconTooSmall, Reason(() => RasterIcon.Check(IconTypes.Png, Png(64, 64, 6))));
        Assert.Equal(CatalogReasons.IconOpaque, Reason(() => RasterIcon.Check(IconTypes.Png, Png(96, 96, 2))));
        Assert.Equal(CatalogReasons.IconOpaque, Reason(() => RasterIcon.Check(IconTypes.Webp, Lossless(96, 96, false))));
        var lossy = Webp("VP8 ", f =>
        {
            BinaryPrimitives.WriteUInt16LittleEndian(f.AsSpan(26), 96);
            BinaryPrimitives.WriteUInt16LittleEndian(f.AsSpan(28), 96);
        });
        Assert.Equal(new ImageHeader(96, 96, false), ImageHeaders.ReadWebp(lossy));
    }

    [Fact]
    public void Files_that_are_not_what_they_claim_are_unreadable()
    {
        Assert.Equal(CatalogReasons.IconUnreadable, Reason(() => RasterIcon.Check(IconTypes.Png, Encoding.ASCII.GetBytes("GIF89a, not a png at all, not at all."))));
        Assert.Equal(CatalogReasons.IconUnreadable, Reason(() => RasterIcon.Check(IconTypes.Webp, Png(96, 96, 6))));
        Assert.Null(ImageHeaders.ReadPng(Png(96, 96, 6)[..20]));
        Assert.Null(ImageHeaders.ReadWebp(Webp("VP8L", _ => { })));
        Assert.Null(ImageHeaders.ReadWebp(Webp("ALPH", _ => { })));
        var broken = Png(96, 96, 2, "teXt");
        BinaryPrimitives.WriteInt32BigEndian(broken.AsSpan(33), int.MaxValue);
        Assert.False(ImageHeaders.ReadPng(broken)!.Value.HasAlpha);
        Assert.False(ImageHeaders.ReadPng(Png(96, 96, 2, "teXt")[..50])!.Value.HasAlpha);
    }

    [Fact]
    public async Task The_library_lists_every_shipped_icon_and_uploads_must_be_base64()
    {
        var root = Path.GetFullPath(Path.Combine(PaoPaths.Resolve(AppContext.BaseDirectory, null).Home, ".."));
        var shipped = Directory.GetFiles(Path.Combine(root, "Frontend/packages/pao_ui/assets/icons"), "*.svg").Select(Path.GetFileNameWithoutExtension);
        Assert.Equal(shipped.Order(), IconLibrary.Keys.Order());
        Assert.Equal(IconLibrary.Keys, (await new ListIconLibraryHandler().Handle(new ListIconLibrary(), CancellationToken.None)).Keys);
        var bad = new UploadIcon(new IconUpload { ContentType = IconTypes.Svg, Data = "not base64!" }, Guid.NewGuid());
        Assert.Equal(CatalogReasons.IconUnreadable, (await Assert.ThrowsAsync<DomainException>(() => new UploadIconHandler(null!).Handle(bad, CancellationToken.None))).Reason);
        Assert.Equal((IconTypes.MaxSvgBytes, IconTypes.MaxRasterBytes), (IconTypes.MaxBytes(IconTypes.Svg), IconTypes.MaxBytes(IconTypes.Webp)));
        Assert.Null(IconTypes.Extension("image/gif"));
    }
}
