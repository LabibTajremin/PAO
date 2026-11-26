using Microsoft.EntityFrameworkCore;
using PAO.EF;
using PAO.EF.Admin;
using PAO.Infrastructure.Data;
using PAO.Infrastructure.Outbox;
using PAO.Lib.Areas.Admin;

namespace PAO.Core.Areas.Admin.Repositories;

/// <summary>The artwork slots of the admin schema (ADR-0040).</summary>
public sealed class ArtworkRepository(PaoDbContext db, OutboxWriter outbox, IClock clock)
{
    /// <summary>Every stored slot by key; slots never seeded or uploaded have no row.</summary>
    public async Task<Dictionary<string, ArtworkRecord>> All(CancellationToken cancellationToken) =>
        await db.Set<ArtworkRecord>().AsNoTracking().ToDictionaryAsync(a => a.Key, cancellationToken);

    /// <summary>The slot's row, or null.</summary>
    public Task<ArtworkRecord?> Find(string key, CancellationToken cancellationToken) =>
        db.Set<ArtworkRecord>().AsNoTracking().FirstOrDefaultAsync(a => a.Key == key, cancellationToken);

    /// <summary>Saves an admin's change with its `ArtworkChanged` event in the command's transaction.</summary>
    public async Task Save(ArtworkRecord a, ArtworkChanged domainEvent, CancellationToken cancellationToken)
    {
        await db.Database.ExecuteSqlAsync($"""
            INSERT INTO admin.artwork_slots (key, url, content_type, seed_url, version, replaced, updated_at, updated_by)
            VALUES ({a.Key}, {a.Url}, {a.ContentType}, {a.SeedUrl}, {a.Version}, {a.Replaced}, {a.UpdatedAt}, {a.UpdatedBy})
            ON CONFLICT (key) DO UPDATE SET url = excluded.url, content_type = excluded.content_type,
                version = excluded.version, replaced = excluded.replaced, updated_at = excluded.updated_at, updated_by = excluded.updated_by
            """, cancellationToken);
        await outbox.Write(db, Schemas.Admin, a.Key, domainEvent, cancellationToken);
    }

    /// <summary>
    /// Records the seed image of a slot. A slot an admin replaced keeps its image; any other
    /// shows the seed, with a new version when the seed changed.
    /// </summary>
    public Task Seed(string key, string url, CancellationToken cancellationToken) => db.Database.ExecuteSqlAsync($"""
        INSERT INTO admin.artwork_slots (key, url, content_type, seed_url, version, replaced, updated_at)
        VALUES ({key}, {url}, {ArtworkFiles.Svg}, {url}, 1, false, {clock.Now})
        ON CONFLICT (key) DO UPDATE SET seed_url = excluded.seed_url,
            url = CASE WHEN artwork_slots.replaced THEN artwork_slots.url ELSE excluded.url END,
            content_type = CASE WHEN artwork_slots.replaced THEN artwork_slots.content_type ELSE excluded.content_type END,
            version = CASE WHEN NOT artwork_slots.replaced AND artwork_slots.url IS DISTINCT FROM excluded.url
                THEN artwork_slots.version + 1 ELSE artwork_slots.version END,
            updated_at = CASE WHEN artwork_slots.seed_url IS DISTINCT FROM excluded.seed_url THEN excluded.updated_at ELSE artwork_slots.updated_at END
        """, cancellationToken);
}
