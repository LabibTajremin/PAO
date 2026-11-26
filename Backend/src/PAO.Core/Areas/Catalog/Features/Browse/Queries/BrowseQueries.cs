using FluentValidation;
using PAO.Core.Areas.Catalog.Repositories;
using PAO.Core.Areas.Catalog.Services;
using PAO.Lib.Areas.Catalog;
using PAO.Lib.Errors;
using PAO.Lib.Mapping;
using PAO.Lib.Mediator;

namespace PAO.Core.Areas.Catalog.Features.Browse.Queries;

/// <summary>The published catalog the apps browse (C-03).</summary>
public sealed record GetPublishedCatalog : IQuery<CatalogTreeView>;

/// <summary>Answers <see cref="GetPublishedCatalog"/> from the cached tree.</summary>
public sealed class GetPublishedCatalogHandler(CatalogTreeService tree, IMapper mapper) : IRequestHandler<GetPublishedCatalog, CatalogTreeView>
{
    /// <inheritdoc />
    public async Task<CatalogTreeView> Handle(GetPublishedCatalog request, CancellationToken cancellationToken) =>
        mapper.Map<CatalogSnapshot, CatalogTreeView>(await tree.Published(cancellationToken));
}

/// <summary>A published service with its published sub-services (C09).</summary>
public sealed record GetPublishedService(Guid ServiceId) : IQuery<ServiceView>;

/// <summary>Answers <see cref="GetPublishedService"/>; `catalog.not_found` for anything unpublished.</summary>
public sealed class GetPublishedServiceHandler(CatalogTreeService tree, IMapper mapper) : IRequestHandler<GetPublishedService, ServiceView>
{
    /// <inheritdoc />
    public async Task<ServiceView> Handle(GetPublishedService request, CancellationToken cancellationToken)
    {
        var services = CatalogRules.ServicesOf((await tree.Published(cancellationToken)).Categories);
        var found = services.FirstOrDefault(s => s.Id == request.ServiceId) ?? throw new DomainException(CatalogReasons.NotFound);
        return mapper.Map<ServiceNode, ServiceView>(found);
    }
}

/// <summary>Published services and sub-services matching Bangla or English text (C08).</summary>
public sealed record SearchCatalog(string Term) : IQuery<CatalogSearchView>;

/// <summary>Needs a search term.</summary>
public sealed class SearchCatalogValidator : AbstractValidator<SearchCatalog>
{
    /// <summary>Declares the rules.</summary>
    public SearchCatalogValidator() => RuleFor(r => r.Term).NotNull().OverridePropertyName("q");
}

/// <summary>Answers <see cref="SearchCatalog"/>; hits under unpublished parents are dropped.</summary>
public sealed class SearchCatalogHandler(CatalogRepository repository, CatalogTreeService tree, IMapper mapper) : IRequestHandler<SearchCatalog, CatalogSearchView>
{
    /// <inheritdoc />
    public async Task<CatalogSearchView> Handle(SearchCatalog request, CancellationToken cancellationToken)
    {
        var (serviceIds, subIds) = await repository.Search(request.Term, cancellationToken);
        var services = CatalogRules.ServicesOf((await tree.Published(cancellationToken)).Categories);
        var serviceById = services.ToDictionary(s => s.Id);
        var subById = services.SelectMany(s => s.SubServices).ToDictionary(s => s.Id);
        return new CatalogSearchView
        {
            Services = mapper.MapAll<ServiceNode, ServiceView>(serviceIds.Where(serviceById.ContainsKey).Select(id => serviceById[id])),
            SubServices = mapper.MapAll<SubServiceNode, SubServiceView>(subIds.Where(subById.ContainsKey).Select(id => subById[id])),
        };
    }
}
