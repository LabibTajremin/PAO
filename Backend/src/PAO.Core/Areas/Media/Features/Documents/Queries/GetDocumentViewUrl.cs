using PAO.Core.Areas.Media.Services;
using PAO.Lib.Areas.Media;
using PAO.Lib.Mapping;
using PAO.Lib.Mediator;

namespace PAO.Core.Areas.Media.Features.Documents.Queries;

/// <summary>A 5-minute view URL for the admin document viewer; each view of a verification document is audited.</summary>
public sealed record GetDocumentViewUrl(Guid MediaId, Guid ViewerId, string ViewerRole) : IQuery<ViewUrlView>;

/// <summary>Answers <see cref="GetDocumentViewUrl"/>.</summary>
public sealed class GetDocumentViewUrlHandler(MediaFiles files, IMapper mapper) : IRequestHandler<GetDocumentViewUrl, ViewUrlView>
{
    /// <inheritdoc />
    public async Task<ViewUrlView> Handle(GetDocumentViewUrl request, CancellationToken cancellationToken) =>
        mapper.Map<ViewUrl, ViewUrlView>(await files.ViewUrl(request.MediaId, new Viewer(request.ViewerId, request.ViewerRole), cancellationToken));
}
