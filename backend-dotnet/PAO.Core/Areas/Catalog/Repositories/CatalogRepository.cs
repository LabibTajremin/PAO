using Microsoft.EntityFrameworkCore;
using PAO.EF;
using PAO.EF.Catalog;
using PAO.Infrastructure.Data;
using PAO.Lib.Areas.Catalog;
using PAO.Lib.Errors;
using PAO.Lib.Mapping;

namespace PAO.Core.Areas.Catalog.Repositories;

/// <summary>Reads the `catalog` schema.</summary>
public sealed class CatalogRepository(PaoDbContext db, IMapper mapper)
{
    /// <summary>Every category with its services and sub-services, published or not: three queries, assembled in memory.</summary>
    public async Task<IReadOnlyList<CategoryNode>> Tree(CancellationToken cancellationToken)
    {
        var categories = await db.Set<CategoryRecord>().OrderBy(c => c.SortOrder).ThenBy(c => c.NameEn).ToListAsync(cancellationToken);
        var services = await db.Set<ServiceRecord>().OrderBy(s => s.SortOrder).ThenBy(s => s.NameEn).ToListAsync(cancellationToken);
        var subs = BatchLoader.GroupBy(await SubServices(cancellationToken), s => s.ServiceId);
        var byCategory = BatchLoader.GroupBy(
            services.Select(s => mapper.Map<ServiceRecord, ServiceNode>(s) with { SubServices = subs.GetValueOrDefault(s.Id, []) }),
            s => s.CategoryId);
        return [.. categories.Select(c => mapper.Map<CategoryRecord, CategoryNode>(c) with { Services = byCategory.GetValueOrDefault(c.Id, []) })];
    }

    /// <summary>Reports whether the category exists.</summary>
    public Task<bool> CategoryExists(Guid id, CancellationToken cancellationToken) =>
        db.Set<CategoryRecord>().AnyAsync(c => c.Id == id, cancellationToken);

    /// <summary>The service with all its sub-services; throws `catalog.not_found`.</summary>
    public async Task<ServiceNode> Service(Guid id, CancellationToken cancellationToken)
    {
        var row = await db.Set<ServiceRecord>().FirstOrDefaultAsync(s => s.Id == id, cancellationToken)
            ?? throw new DomainException(CatalogReasons.NotFound);
        var subs = await SubServices(cancellationToken, serviceId: id);
        return mapper.Map<ServiceRecord, ServiceNode>(row) with { SubServices = subs };
    }

    /// <summary>The sub-service with its current price; throws `catalog.not_found`.</summary>
    public async Task<SubServiceNode> SubService(Guid id, CancellationToken cancellationToken)
    {
        var rows = await SubServices(cancellationToken, id: id);
        return rows.Count == 0 ? throw new DomainException(CatalogReasons.NotFound) : rows[0];
    }

    /// <summary>Price versions, newest first.</summary>
    public async Task<IReadOnlyList<PriceVersionInfo>> PriceHistory(Guid subServiceId, CancellationToken cancellationToken)
    {
        var rows = await db.Set<PriceVersionRecord>().Where(p => p.SubServiceId == subServiceId)
            .OrderByDescending(p => p.EffectiveFrom).ThenByDescending(p => p.Id).ToListAsync(cancellationToken);
        return mapper.MapAll<PriceVersionRecord, PriceVersionInfo>(rows);
    }

    /// <summary>Ids of published services and sub-services matching Bangla or English text, best match first.</summary>
    public async Task<(IReadOnlyList<Guid> Services, IReadOnlyList<Guid> SubServices)> Search(string term, CancellationToken cancellationToken)
    {
        var services = await db.Database.SqlQuery<Guid>($"""
            SELECT id AS "Value" FROM catalog.services
            WHERE published AND (lower(name_en || ' ' || name_bn) LIKE '%' || lower({term}) || '%'
                OR word_similarity(lower({term}), lower(name_en || ' ' || name_bn)) > 0.5)
            ORDER BY word_similarity(lower({term}), lower(name_en || ' ' || name_bn)) DESC LIMIT 20
            """).ToListAsync(cancellationToken);
        var subs = await db.Database.SqlQuery<Guid>($"""
            SELECT id AS "Value" FROM catalog.sub_services
            WHERE published AND (search_text LIKE '%' || lower({term}) || '%' OR word_similarity(lower({term}), search_text) > 0.5)
            ORDER BY word_similarity(lower({term}), search_text) DESC LIMIT 30
            """).ToListAsync(cancellationToken);
        return (services, subs);
    }

    /// <summary>The catalog version.</summary>
    public Task<long> Version(CancellationToken cancellationToken) =>
        db.Set<CatalogVersionRecord>().Select(v => v.Version).FirstAsync(cancellationToken);

    private async Task<IReadOnlyList<SubServiceNode>> SubServices(CancellationToken cancellationToken, Guid? serviceId = null, Guid? id = null)
    {
        var rows = db.Set<SubServiceRecord>().AsQueryable();
        if (serviceId is { } sid)
        {
            rows = rows.Where(s => s.ServiceId == sid);
        }
        if (id is { } one)
        {
            rows = rows.Where(s => s.Id == one);
        }
        var joined = await rows.Join(db.Set<PriceVersionRecord>(), s => s.CurrentPriceVersionId, p => (Guid?)p.Id, (s, p) => new { s, p })
            .OrderBy(x => x.s.SortOrder).ThenBy(x => x.s.NameEn).ToListAsync(cancellationToken);
        return [.. joined.Select(x => mapper.Map<(SubServiceRecord, PriceVersionRecord), SubServiceNode>((x.s, x.p)))];
    }
}
