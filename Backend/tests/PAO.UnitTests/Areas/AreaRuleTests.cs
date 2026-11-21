using System.Text.RegularExpressions;
using PAO.Core.Areas.Catalog.Services;
using PAO.Core.Areas.Media.Services;
using PAO.Core.Areas.Notification.Services;
using PAO.Lib.Areas.Catalog;
using PAO.Lib.Areas.Media;
using PAO.Lib.Areas.Notification;
using PAO.Lib.Common;
using PAO.Lib.Errors;
using PAO.Migrator;

namespace PAO.UnitTests.Areas;

public sealed class CatalogRuleTests
{
    private static readonly Text Name = new() { En = "Electrician", Bn = "ইলেকট্রিশিয়ান" };

    private static ServiceNode Valid() => new()
    {
        Id = Guid.NewGuid(),
        CategoryId = Guid.NewGuid(),
        Name = Name,
        IconKey = "bolt",
        Model = ServiceModel.OnDemand,
        RequiredLevel = 1,
        SearchRadiusM = 5000,
        WomenProvidersOnly = false,
        RequiresLevel2 = false,
        Level2Checklist = [],
        SortOrder = 0,
        Published = true,
    };

    [Fact]
    public void Validates_categories_services_sub_services_and_prices()
    {
        Assert.True(CatalogRules.IsValidCategory(Name, "plug"));
        Assert.False(CatalogRules.IsValidCategory(Name with { Bn = string.Empty }, "p"));
        Assert.False(CatalogRules.IsValidCategory(Name, " "));
        Assert.True(CatalogRules.IsValidService(Valid()));
        ServiceNode[] broken =
        [
            Valid() with { Model = "auction" }, Valid() with { RequiredLevel = 3 }, Valid() with { RequiredLevel = -1 },
            Valid() with { SearchRadiusM = 100 }, Valid() with { SearchRadiusM = 50_001 }, Valid() with { IconKey = " " },
            Valid() with { Name = Name with { Bn = " " } }, Valid() with { RequiresLevel2 = true },
        ];
        Assert.All(broken, s => Assert.False(CatalogRules.IsValidService(s)));
        Assert.True(CatalogRules.IsValidService(Valid() with { RequiresLevel2 = true, RequiredLevel = 2 }));
        Assert.True(CatalogRules.IsValidSubService(Name, "unit", 1));
        Assert.False(CatalogRules.IsValidSubService(Name, "litre", 1));
        Assert.False(CatalogRules.IsValidSubService(Name, "job", 0));
        Assert.True(CatalogRules.IsValidPrice(0));
        Assert.False(CatalogRules.IsValidPrice(-1));
        Assert.Equal(["on_demand", "duration_hire", "listing", "partner_referral"], CatalogRules.Models);
        Assert.Equal(["job", "unit", "hour", "day"], CatalogRules.Units);
    }

    [Fact]
    public void Keeps_only_published_items_without_changing_the_tree()
    {
        SubServiceNode Sub(bool published) => new()
        {
            Id = Guid.NewGuid(),
            ServiceId = Guid.Empty,
            Name = Name,
            Description = Name,
            Inclusions = [],
            Exclusions = [],
            Unit = "job",
            MaxQuantity = 1,
            SortOrder = 0,
            Published = published,
        };
        CategoryNode Category(bool published, params ServiceNode[] services) =>
            new() { Id = Guid.NewGuid(), Name = Name, IconKey = "x", SortOrder = 0, Published = published, Services = services };
        CategoryNode[] tree = [Category(false), Category(true, Valid() with { Published = false }, Valid() with { SubServices = [Sub(true), Sub(false)] })];
        var got = CatalogRules.PublishedOnly(tree);
        Assert.Single(got);
        Assert.Single(Assert.Single(got[0].Services).SubServices);
        Assert.Equal(2, tree[1].Services[1].SubServices.Count);
        Assert.Single(CatalogRules.ServicesOf(got));
    }

    [Fact]
    public void A_broken_rule_is_a_domain_error()
    {
        CatalogChanges.Check(true, CatalogReasons.Invalid);
        Assert.Equal(CatalogReasons.Invalid, Assert.Throws<DomainException>(() => CatalogChanges.Check(false, CatalogReasons.Invalid)).Reason);
    }

    [Fact]
    public void The_seed_file_reads_prices_as_paisa_and_refuses_malformed_yaml()
    {
        var (categories, admins) = SeedFile.Parse(File.ReadAllText(SeedCommand.CatalogFile(PAO.Infrastructure.Hosting.PaoPaths.Resolve(AppContext.BaseDirectory, null))));
        Assert.Equal(7, categories.Count);
        Assert.Equal(50_000, categories[0].Services[0].SubServices[0].PricePaisa);
        Assert.True(categories[3].Services[0].WomenProvidersOnly);
        Assert.Equal(4, admins.Count);
        Assert.Empty(SeedFile.Parse(string.Empty).Categories);
        Assert.Throws<FormatException>(() => SeedFile.Parse("categories: [ {"));
    }
}

public sealed partial class NotificationTemplateTests
{
    [Fact]
    public void Fills_a_template_in_english_or_bangla()
    {
        var data = new Dictionary<string, string> { ["provider"] = "Rahim", ["number"] = "PAO-100001" };
        Assert.Equal("Rahim accepted booking PAO-100001.", NotificationTemplates.Render("booking_accepted", "en", data)!.Body);
        var bn = NotificationTemplates.Render("booking_accepted", "bn", new Dictionary<string, string>(data) { ["provider"] = "রহিম" })!;
        Assert.Equal("বুকিং গৃহীত", bn.Title);
        Assert.Contains("রহিম", bn.Body, StringComparison.Ordinal);
    }

    [Fact]
    public void Reads_other_languages_as_bangla_keeps_unknown_placeholders_and_refuses_unknown_templates()
    {
        Assert.Equal("বুকিং {{number}}-এর কাজ চলছে।", NotificationTemplates.Render("booking_started", "fr", new Dictionary<string, string>())!.Body);
        Assert.Null(NotificationTemplates.Render("nope", "en", new Dictionary<string, string>()));
        Assert.Null(NotificationTemplates.Render("toString", "en", new Dictionary<string, string>()));
    }

    [Fact]
    public void Every_template_has_both_languages_with_the_same_placeholders()
    {
        foreach (var (en, bn) in NotificationTemplates.All.Values)
        {
            Assert.All(new[] { en.Title, en.Body, bn.Title, bn.Body }, t => Assert.NotEmpty(t));
            Assert.Equal(Placeholder().Matches(en.Body).Count, Placeholder().Matches(bn.Body).Count);
        }
        Assert.Equal([true, true, false], new[] { NotificationApp.Customer, NotificationApp.Partner, "provider" }.Select(NotificationApp.IsApp));
    }

    [GeneratedRegex(@"\{\{")]
    private static partial Regex Placeholder();
}

public sealed class AreaContractTests
{
    private static IEnumerable<string> Constants(Type type) =>
        type.GetFields().Where(f => f.IsLiteral).Select(f => (string)f.GetRawConstantValue()!);

    [Fact]
    public void Contracts_keep_the_stored_names_and_scope_their_reasons()
    {
        Assert.Equal(["catalog.CatalogChanged", "catalog.PriceChanged"], Constants(typeof(CatalogEvents)));
        Assert.All(Constants(typeof(CatalogErrors)).Concat(Constants(typeof(CatalogReasons))), r => Assert.StartsWith("catalog.", r, StringComparison.Ordinal));
        Assert.All(Constants(typeof(MediaErrors)).Concat(Constants(typeof(MediaReasons))), r => Assert.StartsWith("media.", r, StringComparison.Ordinal));
        Assert.Equal(["avatar", "nid_front", "nid_back", "selfie", "police_clearance", "skill_proof", "address_proof", "complaint_photo", "level2_photo"], Constants(typeof(MediaPurpose)));
        Assert.Equal(["push", "sms", "inbox"], Constants(typeof(Channel)));
        Assert.Equal(["on_demand", "duration_hire", "listing", "partner_referral"], Constants(typeof(ServiceModel)));
        Assert.Equal(["job", "unit", "hour", "day"], Constants(typeof(PriceUnit)));
    }
}

public sealed class MediaRuleTests
{
    [Fact]
    public void Each_uploader_may_send_only_its_purposes_within_type_and_size()
    {
        Assert.Null(MediaRules.Refusal(Uploader.Customer, MediaPurpose.Avatar, "image/png", 2 << 20));
        Assert.Equal(MediaReasons.Invalid, MediaRules.Refusal(Uploader.Customer, MediaPurpose.Avatar, "image/png", (2 << 20) + 1));
        Assert.Equal(MediaReasons.Invalid, MediaRules.Refusal(Uploader.Customer, MediaPurpose.Avatar, "image/png", 0));
        Assert.Equal(MediaReasons.Invalid, MediaRules.Refusal(Uploader.Customer, MediaPurpose.Avatar, "application/pdf", 10));
        Assert.Equal(MediaReasons.Forbidden, MediaRules.Refusal(Uploader.Customer, MediaPurpose.NidFront, "image/png", 10));
        Assert.Equal(MediaReasons.Forbidden, MediaRules.Refusal(Uploader.Merchant, "unknown", "image/png", 10));
        Assert.Null(MediaRules.Refusal(Uploader.Merchant, MediaPurpose.PoliceClearance, "application/pdf", 5 << 20));
        Assert.Null(MediaRules.Refusal(Uploader.Admin, MediaPurpose.Level2Photo, "image/jpeg", 10));
        Assert.True(MediaRules.IsSensitive(MediaPurpose.Selfie));
        Assert.False(MediaRules.IsSensitive(MediaPurpose.ComplaintPhoto));
        Assert.False(MediaRules.IsSensitive("unknown"));
        var owner = Guid.NewGuid();
        var id = Guid.NewGuid();
        Assert.Equal($"selfie/{owner}/{id}", MediaRules.ObjectKey("selfie", owner, id));
    }
}
