using PAO.Core.Areas.Catalog.Services.Icons;
using PAO.Lib.Areas.Catalog;
using PAO.Lib.Errors;
using PAO.Lib.Mediator;

namespace PAO.Core.Areas.Catalog.Features.Icons.Commands;

/// <summary>Stores an icon an admin uploaded (ADR-0039).</summary>
public sealed record UploadIcon(IconUpload Input, Guid ActorId) : ICommand<CatalogIconView>;

/// <summary>Downloads an icon link once and stores it like an upload (ADR-0039).</summary>
public sealed record AddIconFromLink(IconLink Input, Guid ActorId) : ICommand<CatalogIconView>;

/// <summary>Decodes the upload and stores it.</summary>
public sealed class UploadIconHandler(IconFiles files) : IRequestHandler<UploadIcon, CatalogIconView>
{
    /// <inheritdoc />
    public Task<CatalogIconView> Handle(UploadIcon request, CancellationToken cancellationToken)
    {
        var buffer = new byte[request.Input.Data.Length];
        if (!Convert.TryFromBase64String(request.Input.Data, buffer, out var length))
        {
            throw new DomainException(CatalogReasons.IconUnreadable);
        }
        return files.Store(request.Input.ContentType, buffer[..length], null, request.ActorId, cancellationToken);
    }
}

/// <summary>Fetches the link and stores the file.</summary>
public sealed class AddIconFromLinkHandler(IconFetcher fetcher, IconFiles files) : IRequestHandler<AddIconFromLink, CatalogIconView>
{
    /// <inheritdoc />
    public async Task<CatalogIconView> Handle(AddIconFromLink request, CancellationToken cancellationToken)
    {
        var (type, file) = await fetcher.Fetch(request.Input.Url, cancellationToken);
        return await files.Store(type, file, request.Input.Url, request.ActorId, cancellationToken);
    }
}
