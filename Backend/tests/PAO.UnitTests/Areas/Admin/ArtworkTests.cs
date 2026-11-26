using System.Text;
using PAO.Core.Areas.Admin.Controllers;
using PAO.Core.Areas.Admin.Services;
using PAO.EF.Admin;
using PAO.Infrastructure.Hosting;
using PAO.Lib.Areas.Admin;
using PAO.Lib.Common;
using PAO.Lib.Errors;
using PAO.Lib.Mapping;
using PAO.UnitTests.Areas.Catalog;

namespace PAO.UnitTests.Areas.Admin;

public sealed class ArtworkTests
{
    private static readonly ArtworkSpec Hero = ArtworkSlots.Find("customer.signin.hero")!;

    private static byte[] Svg(string viewBox) =>
        Encoding.UTF8.GetBytes($"<svg xmlns='http://www.w3.org/2000/svg' viewBox='{viewBox}'><path d='M0 0h1'/></svg>");

    private static DomainException Refusal(ArtworkSpec slot, string type, byte[] file) =>
        Assert.Throws<DomainException>(() => ArtworkStore.Checked(slot, type, file));

    [Fact]
    public void Each_app_reads_its_own_slots_and_the_shared_states()
    {
        Assert.Equal(16, ArtworkSlots.All.Count);
        Assert.Null(ArtworkSlots.Find("nope"));
        Assert.DoesNotContain(ArtworkSlots.For(ArtworkSlots.Customer), s => s.App != ArtworkSlots.Customer);
        Assert.Contains(ArtworkSlots.For(ArtworkSlots.Partner), s => s.Key == "offline");
        Assert.Contains(ArtworkSlots.For(ArtworkSlots.Partner), s => s.Key == "empty.notifications");
        Assert.DoesNotContain(ArtworkSlots.For(ArtworkSlots.Partner), s => s.Key == "empty.bookings");
        Assert.Equal(["admin.login.hero"], ArtworkSlots.For(ArtworkSlots.Admin).Select(s => s.Key));
        Assert.Equal(("svg", "png", "webp", null), (ArtworkFiles.Extension(ArtworkFiles.Svg), ArtworkFiles.Extension("image/png"), ArtworkFiles.Extension("image/webp"), ArtworkFiles.Extension("image/gif")));
    }

    [Fact]
    public void Svg_artwork_is_cleaned_and_must_keep_the_slot_ratio()
    {
        Assert.Contains("<path", Encoding.UTF8.GetString(ArtworkStore.Checked(Hero, ArtworkFiles.Svg, Svg("0 0 1170 1200"))), StringComparison.Ordinal);
        ArtworkStore.Checked(Hero, ArtworkFiles.Svg, Svg("0 0 117 118"));
        var wrong = Refusal(Hero, ArtworkFiles.Svg, Svg("0 0 1600 1200"));
        Assert.Equal((AdminReasons.ArtworkWrongSize, (object?)"1170x1200"), (wrong.Reason, wrong.Details!["expected"]));
        Assert.Equal(AdminReasons.ArtworkUnreadable, Refusal(Hero, ArtworkFiles.Svg, Encoding.UTF8.GetBytes("<svg xmlns='http://www.w3.org/2000/svg'/>")).Reason);
        Assert.Equal(AdminReasons.ArtworkUnreadable, Refusal(Hero, ArtworkFiles.Svg, Encoding.UTF8.GetBytes("<html/>")).Reason);
        Assert.Equal(AdminReasons.ArtworkTooLarge, Refusal(Hero, ArtworkFiles.Svg, new byte[ArtworkFiles.MaxSvgBytes + 1]).Reason);
        Assert.Equal(AdminReasons.ArtworkUnreadable, Refusal(Hero, "image/gif", [1]).Reason);
    }

    [Fact]
    public void Png_and_webp_artwork_must_be_the_exact_size_with_transparency()
    {
        var png = IconFileTests.Png(1170, 1200, 6);
        Assert.Same(png, ArtworkStore.Checked(Hero, "image/png", png));
        ArtworkStore.Checked(Hero, "image/webp", IconFileTests.Lossless(1170, 1200, true));
        Assert.Equal("1170x1200", Refusal(Hero, "image/png", IconFileTests.Png(1169, 1200, 6)).Details!["expected"]);
        Assert.Equal(AdminReasons.ArtworkWrongSize, Refusal(Hero, "image/png", IconFileTests.Png(1170, 1199, 6)).Reason);
        Assert.Equal(AdminReasons.ArtworkOpaque, Refusal(Hero, "image/png", IconFileTests.Png(1170, 1200, 2)).Reason);
        Assert.Equal(AdminReasons.ArtworkUnreadable, Refusal(Hero, "image/webp", png).Reason);
        Assert.Equal(AdminReasons.ArtworkTooLarge, Refusal(Hero, "image/png", new byte[ArtworkFiles.MaxRasterBytes + 1]).Reason);
    }

    [Theory]
    [InlineData("""{"en":"Ask for it. PAO it.","bn":"যা চাও, তাই PAO"}""", true)]
    [InlineData("""{"en":"1234567890123456789012345678901234567890","bn":"চাইলেই PAO"}""", true)]
    [InlineData("""{"en":"12345678901234567890123456789012345678901","bn":"x"}""", false)]
    [InlineData("""{"en":"Need it? PAO it.","bn":"  "}""", false)]
    [InlineData("""{"en":"Need it? PAO it."}""", false)]
    [InlineData("""["en"]""", false)]
    [InlineData("null", false)]
    [InlineData("not json", false)]
    public void A_tagline_has_both_languages_of_at_most_forty_characters(string json, bool fits)
    {
        Assert.Equal(fits, Tagline.Parse(json) is not null);
        Assert.Equal(fits, AdminRules.FitsType(Tagline.Type, json));
    }

    [Fact]
    public void A_missing_or_damaged_tagline_reads_as_the_seed_line()
    {
        Assert.Equal(Tagline.Default, Tagline.Read(new Dictionary<string, string>()));
        Assert.Equal(Tagline.Default, Tagline.Read(new Dictionary<string, string> { [Tagline.Key] = "{}" }));
        var stored = Tagline.Read(new Dictionary<string, string> { [Tagline.Key] = """{"en":"Need it? PAO it.","bn":"চাইলেই PAO"}""" });
        Assert.Equal("চাইলেই PAO", stored.Bn);
    }

    [Fact]
    public void The_etag_changes_with_the_config_and_only_then()
    {
        AppConfigView Config(int version) => new(Tagline.Default, [new ArtworkImageView("offline", "https://cdn.example/a.svg", version)]);
        Assert.Equal(AppConfigController.ETag(Config(1)), AppConfigController.ETag(Config(1)));
        Assert.NotEqual(AppConfigController.ETag(Config(1)), AppConfigController.ETag(Config(2)));
        Assert.Matches("^\"[0-9a-f]{32}\"$", AppConfigController.ETag(Config(1)));
        var other = Config(1) with { Tagline = new Text { En = "Need it? PAO it.", Bn = "চাইলেই PAO" } };
        Assert.NotEqual(AppConfigController.ETag(Config(1)), AppConfigController.ETag(other));
    }

    [Fact]
    public void Slots_without_an_image_show_version_zero()
    {
        var mapper = new Mapper([new AdminMappingProfile()]);
        var empty = mapper.Map<(ArtworkSpec, ArtworkRecord?), ArtworkSlotView>((Hero, null));
        Assert.Equal((0, false, (string?)null, (string?)null), (empty.Version, empty.Replaced, empty.Url, empty.ContentType));
        var reset = mapper.Map<(ArtworkSpec, ArtworkRecord?), ArtworkSlotView>((Hero, new ArtworkRecord { Key = Hero.Key, ContentType = "image/svg+xml", Version = 3 }));
        Assert.Equal((3, (string?)null), (reset.Version, reset.ContentType));
    }

    [Fact]
    public void The_seed_artwork_matches_the_design_files_and_fits_its_slots()
    {
        var home = PaoPaths.Resolve(AppContext.BaseDirectory, null).Home;
        var seeds = Directory.GetFiles(Path.Combine(home, "database", "seed", "artwork"), "*.svg");
        Assert.Equal(ArtworkSlots.All.Select(s => s.Key).Order(), seeds.Select(Path.GetFileNameWithoutExtension).Order());
        foreach (var seed in seeds)
        {
            var design = Path.Combine(home, "..", "design", "illustrations", Path.GetFileName(seed));
            Assert.Equal(File.ReadAllBytes(design), File.ReadAllBytes(seed));
            ArtworkStore.Checked(ArtworkSlots.Find(Path.GetFileNameWithoutExtension(seed))!, ArtworkFiles.Svg, File.ReadAllBytes(seed));
        }
    }
}
