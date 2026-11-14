using Microsoft.EntityFrameworkCore;
using PAO.EF;
using PAO.EF.Catalog;
using PAO.Infrastructure.Data;
using PAO.Lib.Areas.Catalog;
using PAO.Lib.Mapping;

namespace PAO.Core.Areas.Catalog.Repositories;

/// <summary>Reads and writes `catalog.banners`; writes join the command's transaction.</summary>
public sealed class BannerRepository(PaoDbContext db, IMapper mapper, IClock clock)
{
    /// <summary>The banners in display order; only published ones when `publishedOnly`.</summary>
    public async Task<IReadOnlyList<BannerView>> List(bool publishedOnly, CancellationToken cancellationToken)
    {
        var rows = await db.Set<BannerRecord>().AsNoTracking().Where(b => !publishedOnly || b.Published)
            .OrderBy(b => b.SortOrder).ThenBy(b => b.TitleEn).ToListAsync(cancellationToken);
        return mapper.MapAll<BannerRecord, BannerView>(rows);
    }

    /// <summary>Reports whether the banner exists.</summary>
    public Task<bool> Exists(Guid id, CancellationToken cancellationToken) =>
        db.Set<BannerRecord>().AnyAsync(b => b.Id == id, cancellationToken);

    /// <summary>Creates or updates a banner.</summary>
    public Task Save(BannerView b, CancellationToken cancellationToken) => db.Database.ExecuteSqlAsync($"""
        INSERT INTO catalog.banners (id, title_en, title_bn, subtitle_en, subtitle_bn, image_url, service_id,
            sort_order, published, created_at, updated_at)
        VALUES ({b.Id}, {b.Title.En}, {b.Title.Bn}, {b.Subtitle?.En}, {b.Subtitle?.Bn}, {b.ImageUrl}, {b.ServiceId},
            {b.SortOrder}, {b.Published}, {clock.Now}, {clock.Now})
        ON CONFLICT (id) DO UPDATE SET title_en = excluded.title_en, title_bn = excluded.title_bn,
            subtitle_en = excluded.subtitle_en, subtitle_bn = excluded.subtitle_bn, image_url = excluded.image_url,
            service_id = excluded.service_id, sort_order = excluded.sort_order, published = excluded.published,
            updated_at = excluded.updated_at
        """, cancellationToken);

    /// <summary>Removes a banner; reports whether one was there.</summary>
    public async Task<bool> Delete(Guid id, CancellationToken cancellationToken) =>
        await db.Database.ExecuteSqlAsync($"DELETE FROM catalog.banners WHERE id = {id}", cancellationToken) > 0;
}
