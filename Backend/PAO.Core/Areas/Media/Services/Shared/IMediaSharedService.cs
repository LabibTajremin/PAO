using PAO.Lib.Areas.Media;

namespace PAO.Core.Areas.Media.Services.Shared;

/// <summary>
/// What other areas may ask of the Media area; the only way they reach it (PRD §9.3
/// rule 1, enforced by the architecture tests).
/// </summary>
public interface IMediaSharedService
{
    /// <summary>Validates the request against the purpose's rules and returns a presigned PUT URL (documents: JPEG/PNG/PDF up to 5 MB; avatars: JPEG/PNG up to 2 MB).</summary>
    Task<UploadTicket> CreateUploadUrl(UploadRequest request, CancellationToken cancellationToken);

    /// <summary>Checks that the object exists and matches the request.</summary>
    Task<MediaObject> ConfirmUpload(Guid ownerId, Guid mediaId, CancellationToken cancellationToken);

    /// <summary>Returns metadata, so callers can check owner and purpose before attaching.</summary>
    Task<MediaObject> GetObject(Guid mediaId, CancellationToken cancellationToken);

    /// <summary>Records that a record references the object, sparing it from the orphan purge.</summary>
    Task MarkAttached(Guid mediaId, CancellationToken cancellationToken);

    /// <summary>Returns a 5-minute signed GET URL; viewing a verification document writes an audit entry (PRD §6.6).</summary>
    Task<ViewUrl> GetViewUrl(ViewRequest request, CancellationToken cancellationToken);

    /// <summary>Removes the object from storage and its record.</summary>
    Task Delete(Guid mediaId, CancellationToken cancellationToken);

    /// <summary>Removes every file the account uploaded, documents included (retention purge).</summary>
    Task DeleteOwnerFiles(Guid ownerId, CancellationToken cancellationToken);
}
