using PAO.Core.Areas.Catalog.Repositories;
using PAO.Core.Areas.Catalog.Services;
using PAO.Infrastructure.Data;
using PAO.Lib.Areas.Catalog;
using PAO.Lib.Common;
using PAO.Lib.Mediator;

namespace PAO.Core.Areas.Catalog.Features.Seed.Commands;

/// <summary>
/// Loads the MVP catalog idempotently (`migrate seed`), every item published in file order,
/// with ids derived from the seed keys. A changed price inserts a new version; unchanged
/// prices are left alone.
/// </summary>
public sealed record SeedCatalog(IReadOnlyList<SeedCategory> Categories) : ICommand;

/// <summary>Writes the seed catalog in one transaction.</summary>
public sealed class SeedCatalogHandler(CatalogRepository repository, CatalogChanges changes, IIdGenerator ids, IClock clock)
    : IRequestHandler<SeedCatalog, Unit>
{
    private static readonly Text NoText = new() { En = string.Empty, Bn = string.Empty };

    /// <inheritdoc />
    public async Task<Unit> Handle(SeedCatalog request, CancellationToken cancellationToken)
    {
        // The prices a previous seed committed, loaded once instead of per item.
        var tree = await repository.Tree(cancellationToken);
        var committed = tree.SelectMany(c => c.Services).SelectMany(s => s.SubServices).ToDictionary(s => s.Id, s => s.Price);
        await changes.Record(
            async w =>
            {
                foreach (var (c, order) in request.Categories.Select((c, i) => (c, i)))
                {
                    var id = SeedIds.For("category", c.Key);
                    await w.SaveCategory(new CategoryNode { Id = id, Name = c.Name, IconKey = c.Icon, SortOrder = order, Published = true }, cancellationToken);
                    foreach (var (s, sortOrder) in c.Services.Select((s, i) => (s, i)))
                    {
                        await SeedService(w, id, s, sortOrder, committed, cancellationToken);
                    }
                }
            },
            cancellationToken);
        return Unit.Value;
    }

    private async Task SeedService(
        CatalogWriteRepository w, Guid categoryId, SeedService s, int sortOrder, Dictionary<Guid, long> committed, CancellationToken cancellationToken)
    {
        var service = new ServiceNode
        {
            Id = SeedIds.For("service", s.Key),
            CategoryId = categoryId,
            Name = s.Name,
            IconKey = s.Icon,
            Model = s.Model,
            RequiredLevel = s.RequiredLevel,
            SearchRadiusM = s.SearchRadiusM,
            WomenProvidersOnly = s.WomenProvidersOnly,
            RequiresLevel2 = s.RequiresLevel2,
            Level2Checklist = s.Level2Checklist,
            SortOrder = sortOrder,
            Published = true,
        };
        CatalogChanges.Check(CatalogRules.IsValidService(service), CatalogReasons.Invalid);
        await w.SaveService(service, cancellationToken);
        foreach (var (sub, order) in s.SubServices.Select((x, i) => (x, i)))
        {
            await SeedSubService(w, service.Id, sub, order, committed.TryGetValue(SeedIds.For("sub-service", sub.Key), out var p) ? p : null, cancellationToken);
        }
    }

    private async Task SeedSubService(
        CatalogWriteRepository w, Guid serviceId, SeedSubService sub, int sortOrder, long? committed, CancellationToken cancellationToken)
    {
        var id = SeedIds.For("sub-service", sub.Key);
        await w.SaveSubService(new SubServiceNode
        {
            Id = id,
            ServiceId = serviceId,
            Name = sub.Name,
            Description = NoText,
            Inclusions = [],
            Exclusions = [],
            Unit = sub.Unit,
            MaxQuantity = sub.MaxQuantity,
            SortOrder = sortOrder,
            Published = true,
        }, cancellationToken);
        if (committed == sub.PricePaisa)
        {
            return;
        }
        await w.AddPrice(new PriceVersionInfo
        {
            Id = ids.NewId(),
            SubServiceId = id,
            Amount = sub.PricePaisa,
            EffectiveFrom = clock.Now,
            CreatedBy = Guid.Empty,
        }, cancellationToken);
    }
}
