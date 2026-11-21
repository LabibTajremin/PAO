using Microsoft.EntityFrameworkCore;
using PAO.EF;
using PAO.Infrastructure.Data;
using PAO.Infrastructure.Outbox;
using PAO.Lib.Areas.Catalog;
using PAO.Lib.Events;
using static PAO.Lib.Areas.Catalog.CatalogMappingProfile;

namespace PAO.Core.Areas.Catalog.Repositories;

/// <summary>
/// Writes catalog rows and outbox events on the scope's context, so they join the
/// command's transaction. Upserts keep reseeding idempotent.
/// </summary>
public sealed class CatalogWriteRepository(PaoDbContext db, OutboxWriter outbox, IClock clock)
{
    /// <summary>Creates or updates a category.</summary>
    public Task SaveCategory(CategoryNode c, CancellationToken cancellationToken) => db.Database.ExecuteSqlAsync($"""
        INSERT INTO catalog.categories (id, name_en, name_bn, icon_key, sort_order, published, created_at, updated_at)
        VALUES ({c.Id}, {c.Name.En}, {c.Name.Bn}, {c.IconKey}, {c.SortOrder}, {c.Published}, {clock.Now}, {clock.Now})
        ON CONFLICT (id) DO UPDATE SET name_en = excluded.name_en, name_bn = excluded.name_bn, icon_key = excluded.icon_key,
            sort_order = excluded.sort_order, published = excluded.published, updated_at = excluded.updated_at
        """, cancellationToken);

    /// <summary>Creates or updates a service (not its sub-services).</summary>
    public Task SaveService(ServiceNode s, CancellationToken cancellationToken) => db.Database.ExecuteSqlAsync($"""
        INSERT INTO catalog.services (id, category_id, name_en, name_bn, icon_key, service_model, required_level, search_radius_m,
            women_providers_only, requires_level_2, level2_checklist, sort_order, published, created_at, updated_at)
        VALUES ({s.Id}, {s.CategoryId}, {s.Name.En}, {s.Name.Bn}, {s.IconKey}, {s.Model}, {s.RequiredLevel}, {s.SearchRadiusM},
            {s.WomenProvidersOnly}, {s.RequiresLevel2}, {ToJson(s.Level2Checklist)}::jsonb, {s.SortOrder}, {s.Published}, {clock.Now}, {clock.Now})
        ON CONFLICT (id) DO UPDATE SET category_id = excluded.category_id, name_en = excluded.name_en, name_bn = excluded.name_bn,
            icon_key = excluded.icon_key, service_model = excluded.service_model, required_level = excluded.required_level,
            search_radius_m = excluded.search_radius_m, women_providers_only = excluded.women_providers_only,
            requires_level_2 = excluded.requires_level_2, level2_checklist = excluded.level2_checklist,
            sort_order = excluded.sort_order, published = excluded.published, updated_at = excluded.updated_at
        """, cancellationToken);

    /// <summary>Creates or updates a sub-service; its price changes only through <see cref="AddPrice"/>.</summary>
    public Task SaveSubService(SubServiceNode s, CancellationToken cancellationToken) => db.Database.ExecuteSqlAsync($"""
        INSERT INTO catalog.sub_services (id, service_id, name_en, name_bn, description, inclusions, exclusions, unit,
            max_quantity, sort_order, published, created_at, updated_at)
        VALUES ({s.Id}, {s.ServiceId}, {s.Name.En}, {s.Name.Bn}, {ToJson(s.Description)}::jsonb, {ToJson(s.Inclusions)}::jsonb,
            {ToJson(s.Exclusions)}::jsonb, {s.Unit}, {s.MaxQuantity}, {s.SortOrder}, {s.Published}, {clock.Now}, {clock.Now})
        ON CONFLICT (id) DO UPDATE SET service_id = excluded.service_id, name_en = excluded.name_en, name_bn = excluded.name_bn,
            description = excluded.description, inclusions = excluded.inclusions, exclusions = excluded.exclusions,
            unit = excluded.unit, max_quantity = excluded.max_quantity, sort_order = excluded.sort_order,
            published = excluded.published, updated_at = excluded.updated_at
        """, cancellationToken);

    /// <summary>Inserts an immutable price version and makes it current.</summary>
    public Task AddPrice(PriceVersionInfo p, CancellationToken cancellationToken) => db.Database.ExecuteSqlAsync($"""
        WITH p AS (
            INSERT INTO catalog.price_versions (id, sub_service_id, amount_paisa, effective_from, created_by)
            VALUES ({p.Id}, {p.SubServiceId}, {p.Amount}, {p.EffectiveFrom}, {p.CreatedBy}) RETURNING id, sub_service_id
        )
        UPDATE catalog.sub_services s SET current_price_version_id = p.id FROM p WHERE s.id = p.sub_service_id
        """, cancellationToken);

    /// <summary>Bumps the catalog version, expiring cached trees; returns the new version.</summary>
    public async Task<long> BumpVersion(CancellationToken cancellationToken) =>
        (await db.Database.SqlQuery<long>($"""UPDATE catalog.catalog_version SET version = version + 1 RETURNING version AS "Value" """)
            .ToListAsync(cancellationToken))[0];

    /// <summary>Stores an event in the catalog outbox, committed with the change.</summary>
    public Task Publish(string aggregateId, IDomainEvent domainEvent, CancellationToken cancellationToken) =>
        outbox.Write(db, Schemas.Catalog, aggregateId, domainEvent, cancellationToken);
}
