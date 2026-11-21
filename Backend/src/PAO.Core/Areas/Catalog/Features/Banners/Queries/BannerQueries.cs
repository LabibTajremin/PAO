using PAO.Core.Areas.Catalog.Repositories;
using PAO.Lib.Areas.Catalog;
using PAO.Lib.Mediator;

namespace PAO.Core.Areas.Catalog.Features.Banners.Queries;

/// <summary>Home banners in display order: every one for admins, the published ones for the apps (C07).</summary>
public sealed record ListBanners(bool PublishedOnly) : IQuery<BannerListView>;

/// <summary>Answers <see cref="ListBanners"/>.</summary>
public sealed class ListBannersHandler(BannerRepository repository) : IRequestHandler<ListBanners, BannerListView>
{
    /// <inheritdoc />
    public async Task<BannerListView> Handle(ListBanners request, CancellationToken cancellationToken) =>
        new() { Banners = await repository.List(request.PublishedOnly, cancellationToken) };
}
