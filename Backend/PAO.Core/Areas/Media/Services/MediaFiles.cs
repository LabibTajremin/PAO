using System.Text.Json.Nodes;
using PAO.Core.Areas.Audit.Services.Shared;
using PAO.Core.Areas.Media.Repositories;
using PAO.Infrastructure.Configuration;
using PAO.Infrastructure.Data;
using PAO.Infrastructure.Storage;
using PAO.Lib.Areas.Audit;
using PAO.Lib.Areas.Media;
using PAO.Lib.Errors;

namespace PAO.Core.Areas.Media.Services;

/// <summary>Who asks to see a file; the role goes into the audit entry.</summary>
public sealed record Viewer(Guid Id, string Role);

/// <summary>
/// Uploads to the private bucket through presigned URLs, confirmation, audited view URLs
/// and deletion (PRD §6.6). The audit contract is resolved on first use, so the areas can
/// start in any order.
/// </summary>
public sealed class MediaFiles(MediaRepository repository, ObjectStore store, PaoSettings settings, IClock clock, IIdGenerator ids, IServiceProvider services)
{
    /// <summary>How long a presigned upload URL works.</summary>
    public static readonly TimeSpan UploadUrlTtl = TimeSpan.FromMinutes(15);

    /// <summary>How long a view URL works (PRD §6.6).</summary>
    public static readonly TimeSpan ViewUrlTtl = TimeSpan.FromMinutes(5);

    /// <summary>Uploads never attached to a record within a day are purged.</summary>
    public static readonly TimeSpan OrphanAfter = TimeSpan.FromHours(24);

    /// <summary>Records a pending upload and returns a presigned PUT for it, after checking the purpose's rules for this uploader.</summary>
    public async Task<UploadTicket> CreateUpload(Guid ownerId, Uploader uploader, UploadInput file, CancellationToken cancellationToken)
    {
        if (MediaRules.Refusal(uploader, file.Purpose, file.ContentType, file.SizeBytes) is { } refusal)
        {
            throw new DomainException(refusal);
        }
        var id = ids.NewId();
        var o = new StoredObject
        {
            Id = id,
            OwnerId = ownerId,
            Purpose = file.Purpose,
            ContentType = file.ContentType,
            SizeBytes = file.SizeBytes,
            Bucket = settings.Storage.BucketPrivate,
            Key = MediaRules.ObjectKey(file.Purpose, ownerId, id),
            Confirmed = false,
            Attached = false,
            CreatedAt = clock.Now,
        };
        await repository.Create(o, cancellationToken);
        var signed = await store.PresignPut(o.Bucket, o.Key, o.ContentType, UploadUrlTtl, o.SizeBytes);
        return new UploadTicket { MediaId = id, Url = signed.Url, Headers = signed.Headers, ExpiresAt = o.CreatedAt + UploadUrlTtl };
    }

    /// <summary>
    /// Marks the owner's object confirmed; confirming twice is harmless. A file that differs
    /// from the request is deleted, so the owner uploads it again.
    /// </summary>
    public async Task<StoredObject> Confirm(Guid ownerId, Guid id, CancellationToken cancellationToken)
    {
        var o = await repository.Get(id, cancellationToken);
        if (o.OwnerId != ownerId)
        {
            throw new DomainException(MediaErrors.NotFound);
        }
        if (o.Confirmed)
        {
            return o;
        }
        ObjectInfo stored;
        try
        {
            stored = await store.Head(o.Bucket, o.Key, cancellationToken);
        }
        catch (ObjectNotFoundException error)
        {
            throw new DomainException(MediaErrors.NotUploaded, error);
        }
        if (stored.Size != o.SizeBytes || stored.ContentType != o.ContentType)
        {
            await store.Delete(o.Bucket, o.Key, cancellationToken);
            throw new DomainException(MediaErrors.NotUploaded);
        }
        await repository.MarkConfirmed(id, cancellationToken);
        return o with { Confirmed = true };
    }

    /// <summary>A 5-minute signed URL for a confirmed file; a view of a verification document is audited first, so none goes unrecorded.</summary>
    public async Task<ViewUrl> ViewUrl(Guid id, Viewer viewer, CancellationToken cancellationToken)
    {
        var o = await repository.Get(id, cancellationToken);
        if (!o.Confirmed)
        {
            throw new DomainException(MediaErrors.NotFound);
        }
        if (MediaRules.IsSensitive(o.Purpose))
        {
            await services.GetRequiredService<IAuditSharedService>().Record(new AuditEntry
            {
                Id = ids.NewId(),
                At = clock.Now,
                ActorId = viewer.Id,
                ActorRole = viewer.Role,
                Action = "media.document_viewed",
                SubjectType = "media",
                SubjectId = o.Id.ToString(),
                Reason = string.Empty,
                After = new JsonObject { ["purpose"] = o.Purpose, ["owner"] = o.OwnerId.ToString() },
            }, cancellationToken);
        }
        var url = await store.PresignGet(o.Bucket, o.Key, ViewUrlTtl);
        return new ViewUrl { Url = url, ExpiresAt = clock.Now + ViewUrlTtl };
    }

    /// <summary>Removes the file, then its record; throws `media.not_found`.</summary>
    public async Task Delete(Guid id, CancellationToken cancellationToken)
    {
        var o = await repository.Get(id, cancellationToken);
        await Remove([o], cancellationToken);
    }

    /// <summary>
    /// Deletes an account's files. Verification documents outlive the account by the
    /// retention period (ADR-0023), so they go only when `documents` is set.
    /// </summary>
    public async Task<int> DeleteOwned(Guid ownerId, bool documents, CancellationToken cancellationToken)
    {
        var owned = await repository.ByOwner(ownerId, cancellationToken);
        var doomed = owned.Where(o => documents || !MediaRules.IsSensitive(o.Purpose)).ToList();
        await Remove(doomed, cancellationToken);
        return doomed.Count;
    }

    /// <summary>Deletes uploads never attached within a day; returns how many went.</summary>
    public async Task<int> PurgeOrphans(CancellationToken cancellationToken)
    {
        var orphans = await repository.Orphans(clock.Now - OrphanAfter, cancellationToken);
        await Remove(orphans, cancellationToken);
        return orphans.Count;
    }

    // Storage has no batch delete for this store, so files go one by one; the records go
    // in one statement.
    private async Task Remove(IReadOnlyList<StoredObject> objects, CancellationToken cancellationToken)
    {
        foreach (var o in objects)
        {
            await store.Delete(o.Bucket, o.Key, cancellationToken);
        }
        if (objects.Count > 0)
        {
            await repository.DeleteMany([.. objects.Select(o => o.Id)], cancellationToken);
        }
    }
}
