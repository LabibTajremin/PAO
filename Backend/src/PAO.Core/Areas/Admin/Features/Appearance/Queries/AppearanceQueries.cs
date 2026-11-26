using PAO.Core.Areas.Admin.Repositories;
using PAO.Core.Areas.Admin.Services;
using PAO.EF.Admin;
using PAO.Lib.Areas.Admin;
using PAO.Lib.Mapping;
using PAO.Lib.Mediator;

namespace PAO.Core.Areas.Admin.Features.Appearance.Queries;

/// <summary>Every artwork slot for the admin page.</summary>
public sealed record ListArtwork : IQuery<ArtworkSlotList>;

/// <summary>The tagline and artwork `App` shows (customer, partner or admin).</summary>
public sealed record GetAppConfig(string App) : IQuery<AppConfigView>;

/// <summary>Joins the fixed slot list with the stored rows.</summary>
public sealed class ListArtworkHandler(ArtworkRepository repository, IMapper mapper) : IRequestHandler<ListArtwork, ArtworkSlotList>
{
    /// <inheritdoc />
    public async Task<ArtworkSlotList> Handle(ListArtwork request, CancellationToken cancellationToken)
    {
        var stored = await repository.All(cancellationToken);
        return new ArtworkSlotList([.. ArtworkSlots.All.Select(s => mapper.Map<(ArtworkSpec, ArtworkRecord?), ArtworkSlotView>((s, stored.GetValueOrDefault(s.Key))))]);
    }
}

/// <summary>Reads the tagline setting and the app's slots that have an image.</summary>
public sealed class GetAppConfigHandler(ArtworkRepository repository, SettingValues settings) : IRequestHandler<GetAppConfig, AppConfigView>
{
    /// <inheritdoc />
    public async Task<AppConfigView> Handle(GetAppConfig request, CancellationToken cancellationToken)
    {
        var stored = await repository.All(cancellationToken);
        var artwork = ArtworkSlots.For(request.App)
            .Select(s => stored.GetValueOrDefault(s.Key))
            .OfType<ArtworkRecord>()
            .Where(r => r.Url is not null)
            .Select(r => new ArtworkImageView(r.Key, r.Url!, r.Version));
        return new AppConfigView(Tagline.Read(await settings.Values(cancellationToken)), [.. artwork]);
    }
}
