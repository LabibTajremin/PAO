using PAO.Core.Areas.Media.Services;
using PAO.Lib.Areas.Media;
using PAO.Lib.Mediator;

namespace PAO.Core.Areas.Media.Features.Retention.Commands;

/// <summary>Answers <see cref="PurgeOrphanMedia"/> for the worker's `media.purge_orphans` job.</summary>
public sealed class PurgeOrphanMediaHandler(MediaFiles files) : IRequestHandler<PurgeOrphanMedia, int>
{
    /// <inheritdoc />
    public Task<int> Handle(PurgeOrphanMedia request, CancellationToken cancellationToken) => files.PurgeOrphans(cancellationToken);
}

/// <summary>Answers <see cref="DeleteAccountMedia"/> when `identity.AccountDeleted` arrives.</summary>
public sealed class DeleteAccountMediaHandler(MediaFiles files) : IRequestHandler<DeleteAccountMedia, int>
{
    /// <inheritdoc />
    public Task<int> Handle(DeleteAccountMedia request, CancellationToken cancellationToken) =>
        files.DeleteOwned(request.AccountId, false, cancellationToken);
}
