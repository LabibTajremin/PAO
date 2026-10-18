using PAO.Lib.Areas.Catalog;
using PAO.Lib.Common;
using YamlDotNet.Serialization;
using YamlDotNet.Serialization.NamingConventions;

namespace PAO.Migrator;

/// <summary>A demo admin of the seed file; Identity seeds them (dev and staging only).</summary>
public sealed record SeedAdmin(string Email, string Name, IReadOnlyList<string> Roles);

/// <summary>Reads `Seed/catalog.yaml`: the catalog, prices in whole taka, and the demo admins.</summary>
public static class SeedFile
{
    /// <summary>Parses the file; prices become paisa. Throws <see cref="FormatException"/> for a malformed file.</summary>
    public static (IReadOnlyList<SeedCategory> Categories, IReadOnlyList<SeedAdmin> Admins) Parse(string yaml)
    {
        Root file;
        try
        {
            file = new DeserializerBuilder().WithNamingConvention(UnderscoredNamingConvention.Instance).Build().Deserialize<Root>(yaml) ?? new Root();
        }
        catch (YamlDotNet.Core.YamlException error)
        {
            throw new FormatException("parse seed", error);
        }
        var categories = file.Categories.Select(c => new SeedCategory
        {
            Key = c.Key,
            Name = c.Name.ToText(),
            Icon = c.Icon,
            Services = [.. c.Services.Select(s => new SeedService
            {
                Key = s.Key,
                Name = s.Name.ToText(),
                Icon = s.Icon,
                Model = s.Model,
                RequiredLevel = s.RequiredLevel,
                SearchRadiusM = s.SearchRadiusM,
                WomenProvidersOnly = s.WomenProvidersOnly,
                RequiresLevel2 = s.RequiresLevel2,
                Level2Checklist = [.. s.Level2Checklist.Select(t => t.ToText())],
                SubServices = [.. s.SubServices.Select(ss => new SeedSubService
                {
                    Key = ss.Key, Name = ss.Name.ToText(), Unit = ss.Unit, PricePaisa = ss.Price * 100, MaxQuantity = ss.MaxQuantity,
                })],
            })],
        });
        return ([.. categories], [.. file.Admins.Select(a => new SeedAdmin(a.Email, a.Name, a.Roles))]);
    }

    // YamlDotNet fills these mutable shapes; they never leave this class.
    private sealed class Root
    {
        public List<CategoryRow> Categories { get; set; } = [];
        public List<AdminRow> Admins { get; set; } = [];
    }

    private sealed class TextRow
    {
        public string En { get; set; } = string.Empty;
        public string Bn { get; set; } = string.Empty;

        public Text ToText() => new() { En = En, Bn = Bn };
    }

    private sealed class CategoryRow
    {
        public string Key { get; set; } = string.Empty;
        public TextRow Name { get; set; } = new();
        public string Icon { get; set; } = string.Empty;
        public List<ServiceRow> Services { get; set; } = [];
    }

    private sealed class ServiceRow
    {
        public string Key { get; set; } = string.Empty;
        public TextRow Name { get; set; } = new();
        public string Icon { get; set; } = string.Empty;
        public string Model { get; set; } = string.Empty;
        public int RequiredLevel { get; set; }
        public int SearchRadiusM { get; set; }
        public bool WomenProvidersOnly { get; set; }
        [YamlMember(Alias = "requires_level_2")]
        public bool RequiresLevel2 { get; set; }
        [YamlMember(Alias = "level2_checklist")]
        public List<TextRow> Level2Checklist { get; set; } = [];
        public List<SubServiceRow> SubServices { get; set; } = [];
    }

    private sealed class SubServiceRow
    {
        public string Key { get; set; } = string.Empty;
        public TextRow Name { get; set; } = new();
        public string Unit { get; set; } = string.Empty;
        public long Price { get; set; }
        public int MaxQuantity { get; set; }
    }

    private sealed class AdminRow
    {
        public string Email { get; set; } = string.Empty;
        public string Name { get; set; } = string.Empty;
        public List<string> Roles { get; set; } = [];
    }
}
