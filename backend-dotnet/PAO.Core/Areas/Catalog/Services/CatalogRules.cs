using PAO.Lib.Areas.Catalog;
using PAO.Lib.Common;

namespace PAO.Core.Areas.Catalog.Services;

/// <summary>The catalog rules (PRD §4): names, icons, models, levels, radius, units and prices.</summary>
public static class CatalogRules
{
    /// <summary>The service models, in PRD order.</summary>
    public static readonly IReadOnlyList<string> Models = [ServiceModel.OnDemand, ServiceModel.DurationHire, ServiceModel.Listing, ServiceModel.PartnerReferral];

    /// <summary>What one quantity of a sub-service can mean.</summary>
    public static readonly IReadOnlyList<string> Units = [PriceUnit.Job, PriceUnit.Unit, PriceUnit.Hour, PriceUnit.Day];

    /// <summary>Reports whether a category has both names and an icon.</summary>
    public static bool IsValidCategory(Text name, string iconKey) => ValidName(name) && Filled(iconKey);

    /// <summary>Reports whether a service keeps the catalog rules.</summary>
    public static bool IsValidService(ServiceNode s)
    {
        var wellFormed = ValidName(s.Name) && Filled(s.IconKey) && Models.Contains(s.Model)
            && s.RequiredLevel is >= 0 and <= 2 && s.SearchRadiusM is >= 500 and <= 50_000;
        // A service that needs Level 2 before the first booking requires level 2 (D7).
        return wellFormed && (!s.RequiresLevel2 || s.RequiredLevel >= 2);
    }

    /// <summary>Reports whether a sub-service has names, a known unit and a positive maximum.</summary>
    public static bool IsValidSubService(Text name, string unit, int maxQuantity) =>
        ValidName(name) && Units.Contains(unit) && maxQuantity >= 1;

    /// <summary>Reports whether an amount in paisa can be a price.</summary>
    public static bool IsValidPrice(long amount) => amount >= 0;

    /// <summary>Keeps only published categories, services and sub-services.</summary>
    public static IReadOnlyList<CategoryNode> PublishedOnly(IEnumerable<CategoryNode> tree) =>
        [.. tree.Where(c => c.Published).Select(c => c with
        {
            Services = [.. c.Services.Where(s => s.Published).Select(s => s with { SubServices = [.. s.SubServices.Where(ss => ss.Published)] })],
        })];

    /// <summary>Every service of a tree, in tree order.</summary>
    public static IReadOnlyList<ServiceNode> ServicesOf(IEnumerable<CategoryNode> tree) => [.. tree.SelectMany(c => c.Services)];

    private static bool Filled(string s) => !string.IsNullOrWhiteSpace(s);

    private static bool ValidName(Text n) => Filled(n.En) && Filled(n.Bn);
}
