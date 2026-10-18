using System.Globalization;
using System.Text.Json;
using PAO.EF.Catalog;
using PAO.Lib.Common;
using PAO.Lib.Mapping;

namespace PAO.Lib.Areas.Catalog;

/// <summary>The Catalog area's maps: db rows to tree nodes, nodes to views, inputs to nodes.</summary>
public sealed class CatalogMappingProfile : IMappingProfile
{
    private static readonly JsonSerializerOptions Json = new(JsonSerializerDefaults.Web);

    /// <summary>Texts as the jsonb columns store them.</summary>
    public static string ToJson<T>(T value) => JsonSerializer.Serialize(value, Json);

    /// <inheritdoc />
    public void Configure(MappingRegistry registry)
    {
        registry
            .Add<CategoryRecord, CategoryNode>((c, _) => new CategoryNode
            {
                Id = c.Id,
                Name = new Text { En = c.NameEn, Bn = c.NameBn },
                IconKey = c.IconKey,
                SortOrder = c.SortOrder,
                Published = c.Published,
            })
            .Add<ServiceRecord, ServiceNode>((s, _) => new ServiceNode
            {
                Id = s.Id,
                CategoryId = s.CategoryId,
                Name = new Text { En = s.NameEn, Bn = s.NameBn },
                IconKey = s.IconKey,
                Model = s.ServiceModel,
                RequiredLevel = s.RequiredLevel,
                SearchRadiusM = s.SearchRadiusM,
                WomenProvidersOnly = s.WomenProvidersOnly,
                RequiresLevel2 = s.RequiresLevel2,
                Level2Checklist = Texts(s.Level2Checklist),
                SortOrder = s.SortOrder,
                Published = s.Published,
            })
            .Add<(SubServiceRecord Row, PriceVersionRecord Price), SubServiceNode>((p, _) => SubService(p.Row, p.Price))
            .Add<PriceVersionRecord, PriceVersionInfo>((p, _) => new PriceVersionInfo
            {
                Id = p.Id,
                SubServiceId = p.SubServiceId,
                Amount = p.AmountPaisa,
                EffectiveFrom = p.EffectiveFrom,
                CreatedBy = p.CreatedBy,
            });
        Views(registry);
        Inputs(registry);
    }

    private static void Views(MappingRegistry registry) => registry
        .Add<SubServiceNode, SubServiceView>((s, _) => new SubServiceView
        {
            Id = s.Id,
            ServiceId = s.ServiceId,
            Name = s.Name,
            Description = s.Description.En.Length == 0 ? null : s.Description,
            Inclusions = s.Inclusions,
            Exclusions = s.Exclusions,
            Unit = s.Unit,
            Price = s.Price,
            PriceVersionId = s.PriceVersionId,
            MaxQuantity = s.MaxQuantity,
            Published = s.Published,
        })
        .Add<ServiceNode, ServiceView>((s, m) => new ServiceView
        {
            Id = s.Id,
            CategoryId = s.CategoryId,
            Name = s.Name,
            IconKey = s.IconKey,
            ServiceModel = s.Model,
            RequiredLevel = s.RequiredLevel,
            SearchRadiusM = s.SearchRadiusM,
            WomenProvidersOnly = s.WomenProvidersOnly,
            RequiresLevel2 = s.RequiresLevel2,
            Level2Checklist = s.Level2Checklist,
            Published = s.Published,
            SubServices = m.MapAll<SubServiceNode, SubServiceView>(s.SubServices),
        })
        .Add<CategoryNode, CategoryView>((c, m) => new CategoryView
        {
            Id = c.Id,
            Name = c.Name,
            IconKey = c.IconKey,
            SortOrder = c.SortOrder,
            Published = c.Published,
            Services = m.MapAll<ServiceNode, ServiceView>(c.Services),
        })
        .Add<CatalogSnapshot, CatalogTreeView>((t, m) => new CatalogTreeView
        {
            Version = t.Version,
            Categories = m.MapAll<CategoryNode, CategoryView>(t.Categories),
        })
        .Add<PriceVersionInfo, PriceVersionView>((p, _) => new PriceVersionView
        {
            Id = p.Id,
            SubServiceId = p.SubServiceId,
            Amount = p.Amount,
            CreatedBy = p.CreatedBy,
            EffectiveFrom = p.EffectiveFrom.UtcDateTime.ToString("yyyy-MM-dd'T'HH:mm:ss.fff'Z'", CultureInfo.InvariantCulture),
        });

    private static void Inputs(MappingRegistry registry) => registry
        .Add<(Guid Id, CategoryInput Input), CategoryNode>((p, _) => new CategoryNode
        {
            Id = p.Id,
            Name = p.Input.Name,
            IconKey = p.Input.IconKey,
            SortOrder = p.Input.SortOrder ?? 0,
            Published = p.Input.Published ?? false,
        })
        .Add<(Guid Id, ServiceInput Input), ServiceNode>((p, _) => new ServiceNode
        {
            Id = p.Id,
            CategoryId = p.Input.CategoryId,
            Name = p.Input.Name,
            IconKey = p.Input.IconKey,
            Model = p.Input.ServiceModel,
            RequiredLevel = p.Input.RequiredLevel,
            SearchRadiusM = p.Input.SearchRadiusM,
            WomenProvidersOnly = p.Input.WomenProvidersOnly ?? false,
            RequiresLevel2 = p.Input.RequiresLevel2 ?? false,
            Level2Checklist = p.Input.Level2Checklist ?? [],
            SortOrder = 0,
            Published = p.Input.Published ?? false,
        })
        .Add<(Guid Id, SubServiceInput Input), SubServiceNode>((p, _) => new SubServiceNode
        {
            Id = p.Id,
            ServiceId = p.Input.ServiceId,
            Name = p.Input.Name,
            Description = p.Input.Description ?? new Text { En = string.Empty, Bn = string.Empty },
            Inclusions = p.Input.Inclusions ?? [],
            Exclusions = p.Input.Exclusions ?? [],
            Unit = p.Input.Unit,
            MaxQuantity = p.Input.MaxQuantity ?? 1,
            SortOrder = 0,
            Published = p.Input.Published ?? false,
        });

    private static SubServiceNode SubService(SubServiceRecord s, PriceVersionRecord p) => new()
    {
        Id = s.Id,
        ServiceId = s.ServiceId,
        Name = new Text { En = s.NameEn, Bn = s.NameBn },
        Description = JsonSerializer.Deserialize<Text>(s.Description, Json)!,
        Inclusions = Texts(s.Inclusions),
        Exclusions = Texts(s.Exclusions),
        Unit = s.Unit,
        MaxQuantity = s.MaxQuantity,
        SortOrder = s.SortOrder,
        Published = s.Published,
        PriceVersionId = p.Id,
        Price = p.AmountPaisa,
    };

    private static IReadOnlyList<Text> Texts(string json) => JsonSerializer.Deserialize<List<Text>>(json, Json)!;
}
