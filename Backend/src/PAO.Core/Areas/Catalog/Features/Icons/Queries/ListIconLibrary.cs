using PAO.Lib.Areas.Catalog;
using PAO.Lib.Mediator;

namespace PAO.Core.Areas.Catalog.Features.Icons.Queries;

/// <summary>The library icons every app ships, for the admin icon picker.</summary>
public sealed record ListIconLibrary : IQuery<IconLibraryView>;

/// <summary>Returns <see cref="IconLibrary.Keys"/>.</summary>
public sealed class ListIconLibraryHandler : IRequestHandler<ListIconLibrary, IconLibraryView>
{
    /// <inheritdoc />
    public Task<IconLibraryView> Handle(ListIconLibrary request, CancellationToken cancellationToken) =>
        Task.FromResult(new IconLibraryView { Keys = IconLibrary.Keys });
}
