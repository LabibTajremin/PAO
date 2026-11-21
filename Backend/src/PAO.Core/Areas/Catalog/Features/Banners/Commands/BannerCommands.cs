using FluentValidation;
using PAO.Core.Areas.Catalog.Repositories;
using PAO.Core.Areas.Catalog.Services;
using PAO.Infrastructure.Data;
using PAO.Lib.Areas.Catalog;
using PAO.Lib.Mapping;
using PAO.Lib.Mediator;

namespace PAO.Core.Areas.Catalog.Features.Banners.Commands;

/// <summary>Creates a home banner, or updates the one with `Id`.</summary>
public sealed record SaveBanner(Guid? Id, BannerInput Input) : ICommand<BannerView>;

/// <summary>Removes a home banner; `catalog.not_found` when there is none.</summary>
public sealed record DeleteBanner(Guid Id) : ICommand;

/// <summary>Both titles, a whole subtitle if any, an https image if any.</summary>
public sealed class SaveBannerValidator : AbstractValidator<SaveBanner>
{
    /// <summary>Declares the rules.</summary>
    public SaveBannerValidator() =>
        RuleFor(r => r.Input).Must(CatalogRules.IsValidBanner).WithMessage(CatalogReasons.Invalid);
}

/// <summary>Saves the banner; the service it opens must exist.</summary>
public sealed class SaveBannerHandler(BannerRepository banners, CatalogRepository catalog, IIdGenerator ids, IMapper mapper)
    : IRequestHandler<SaveBanner, BannerView>
{
    /// <inheritdoc />
    public async Task<BannerView> Handle(SaveBanner request, CancellationToken cancellationToken)
    {
        var missingBanner = request.Id is { } id && !await banners.Exists(id, cancellationToken);
        var missingService = request.Input.ServiceId is { } service && !await catalog.ServiceExists(service, cancellationToken);
        CatalogChanges.Check(!missingBanner && !missingService, CatalogReasons.NotFound);
        var banner = mapper.Map<(Guid, BannerInput), BannerView>((request.Id ?? ids.NewId(), request.Input));
        await banners.Save(banner, cancellationToken);
        return banner;
    }

}

/// <summary>Answers <see cref="DeleteBanner"/>.</summary>
public sealed class DeleteBannerHandler(BannerRepository banners) : IRequestHandler<DeleteBanner, Unit>
{
    /// <inheritdoc />
    public async Task<Unit> Handle(DeleteBanner request, CancellationToken cancellationToken)
    {
        CatalogChanges.Check(await banners.Delete(request.Id, cancellationToken), CatalogReasons.NotFound);
        return Unit.Value;
    }
}
