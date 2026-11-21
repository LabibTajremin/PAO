using PAO.Core.Areas.Media.Repositories;
using PAO.Lib.Areas.Media;
using PAO.Lib.Errors;
using PAO.Lib.Mapping;

namespace PAO.Core.Areas.Media.Services.Shared;

/// <summary>The Media contract for the other areas; both upload refusals become `media.upload_invalid`.</summary>
public sealed class MediaSharedService(MediaFiles files, MediaRepository repository, IMapper mapper) : IMediaSharedService
{
    /// <summary>Uploads made by other areas, such as Level 2 visit photos recorded by verifiers.</summary>
    public async Task<UploadTicket> CreateUploadUrl(UploadRequest request, CancellationToken cancellationToken)
    {
        try
        {
            var file = new UploadInput { Purpose = request.Purpose, ContentType = request.ContentType, SizeBytes = request.SizeBytes };
            return await files.CreateUpload(request.OwnerId, Uploader.Admin, file, cancellationToken);
        }
        catch (DomainException error) when (error.Reason is MediaReasons.Invalid or MediaReasons.Forbidden)
        {
            throw new DomainException(MediaErrors.UploadInvalid, error);
        }
    }

    /// <inheritdoc />
    public async Task<MediaObject> ConfirmUpload(Guid ownerId, Guid mediaId, CancellationToken cancellationToken) =>
        mapper.Map<StoredObject, MediaObject>(await files.Confirm(ownerId, mediaId, cancellationToken));

    /// <inheritdoc />
    public async Task<MediaObject> GetObject(Guid mediaId, CancellationToken cancellationToken) =>
        mapper.Map<StoredObject, MediaObject>(await repository.Get(mediaId, cancellationToken));

    /// <inheritdoc />
    public Task MarkAttached(Guid mediaId, CancellationToken cancellationToken) => repository.MarkAttached(mediaId, cancellationToken);

    /// <inheritdoc />
    public Task<ViewUrl> GetViewUrl(ViewRequest request, CancellationToken cancellationToken) =>
        files.ViewUrl(request.MediaId, new Viewer(request.ViewerId, request.ViewerRole), cancellationToken);

    /// <inheritdoc />
    public Task Delete(Guid mediaId, CancellationToken cancellationToken) => files.Delete(mediaId, cancellationToken);

    /// <inheritdoc />
    public Task DeleteOwnerFiles(Guid ownerId, CancellationToken cancellationToken) => files.DeleteOwned(ownerId, true, cancellationToken);
}
