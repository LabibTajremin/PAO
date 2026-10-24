using Microsoft.EntityFrameworkCore;
using PAO.EF;
using PAO.EF.Media;
using PAO.Infrastructure.Data;
using PAO.Lib.Areas.Media;
using PAO.Lib.Errors;
using PAO.Lib.Mapping;

namespace PAO.Core.Areas.Media.Repositories;

/// <summary>Stores `media.objects` rows.</summary>
public sealed class MediaRepository(PaoDbContext db, IMapper mapper, IClock clock)
{
    /// <summary>Records a pending upload.</summary>
    public async Task Create(StoredObject o, CancellationToken cancellationToken)
    {
        db.Set<MediaObjectRecord>().Add(new MediaObjectRecord
        {
            Id = o.Id,
            OwnerId = o.OwnerId,
            Purpose = o.Purpose,
            ContentType = o.ContentType,
            SizeBytes = o.SizeBytes,
            Bucket = o.Bucket,
            ObjectKey = o.Key,
            Status = "pending",
            CreatedAt = o.CreatedAt,
        });
        await db.SaveChangesAsync(cancellationToken);
        db.ChangeTracker.Clear();
    }

    /// <summary>The object; throws `media.not_found`.</summary>
    public async Task<StoredObject> Get(Guid id, CancellationToken cancellationToken)
    {
        var row = await db.Set<MediaObjectRecord>().FirstOrDefaultAsync(o => o.Id == id, cancellationToken)
            ?? throw new DomainException(MediaErrors.NotFound);
        return mapper.Map<MediaObjectRecord, StoredObject>(row);
    }

    /// <summary>Marks the upload confirmed.</summary>
    public Task MarkConfirmed(Guid id, CancellationToken cancellationToken) =>
        db.Set<MediaObjectRecord>().Where(o => o.Id == id)
            .ExecuteUpdateAsync(u => u.SetProperty(o => o.Status, "confirmed").SetProperty(o => o.ConfirmedAt, clock.Now), cancellationToken);

    /// <summary>Spares the object from the orphan purge; throws `media.not_found`.</summary>
    public async Task MarkAttached(Guid id, CancellationToken cancellationToken)
    {
        var changed = await db.Set<MediaObjectRecord>().Where(o => o.Id == id)
            .ExecuteUpdateAsync(u => u.SetProperty(o => o.Attached, true), cancellationToken);
        if (changed == 0)
        {
            throw new DomainException(MediaErrors.NotFound);
        }
    }

    /// <summary>Objects never attached and created before `createdBefore`, oldest first (at most 500 per run).</summary>
    public async Task<IReadOnlyList<StoredObject>> Orphans(DateTimeOffset createdBefore, CancellationToken cancellationToken) =>
        mapper.MapAll<MediaObjectRecord, StoredObject>(await db.Set<MediaObjectRecord>()
            .Where(o => !o.Attached && o.CreatedAt < createdBefore).OrderBy(o => o.CreatedAt).Take(500).ToListAsync(cancellationToken));

    /// <summary>Every object the account uploaded, oldest first.</summary>
    public async Task<IReadOnlyList<StoredObject>> ByOwner(Guid ownerId, CancellationToken cancellationToken) =>
        mapper.MapAll<MediaObjectRecord, StoredObject>(await db.Set<MediaObjectRecord>()
            .Where(o => o.OwnerId == ownerId).OrderBy(o => o.CreatedAt).ToListAsync(cancellationToken));

    /// <summary>Removes many records with one statement.</summary>
    public Task DeleteMany(IReadOnlyCollection<Guid> ids, CancellationToken cancellationToken) =>
        db.Set<MediaObjectRecord>().Where(o => ids.Contains(o.Id)).ExecuteDeleteAsync(cancellationToken);
}
