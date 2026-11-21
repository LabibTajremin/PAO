using FluentValidation;
using PAO.Core.Areas.Catalog.Repositories;
using PAO.Core.Areas.Catalog.Services;
using PAO.Infrastructure.Data;
using PAO.Lib.Areas.Catalog;
using PAO.Lib.Errors;
using PAO.Lib.Mapping;
using PAO.Lib.Mediator;

namespace PAO.Core.Areas.Catalog.Features.ManageCatalog.Commands;

/// <summary>Creates a service in an existing category, or updates the one with `Id` (A-02).</summary>
public sealed record SaveService(Guid? Id, ServiceInput Input) : ICommand<ServiceView>;

/// <summary>The catalog rules for services.</summary>
public sealed class SaveServiceValidator : AbstractValidator<SaveService>
{
    /// <summary>Declares the rules.</summary>
    public SaveServiceValidator(IMapper mapper) =>
        RuleFor(r => r.Input).Must(i => CatalogRules.IsValidService(mapper.Map<(Guid, ServiceInput), ServiceNode>((Guid.Empty, i))))
            .WithMessage(CatalogReasons.Invalid);
}

/// <summary>Saves the service and bumps the catalog version.</summary>
public sealed class SaveServiceHandler(CatalogRepository repository, CatalogChanges changes, IIdGenerator ids, IMapper mapper)
    : IRequestHandler<SaveService, ServiceView>
{
    /// <inheritdoc />
    public async Task<ServiceView> Handle(SaveService request, CancellationToken cancellationToken)
    {
        var service = mapper.Map<(Guid, ServiceInput), ServiceNode>((request.Id ?? ids.NewId(), request.Input));
        if (!await repository.CategoryExists(service.CategoryId, cancellationToken))
        {
            throw new DomainException(CatalogReasons.NotFound);
        }
        if (request.Id is { } id)
        {
            await repository.Service(id, cancellationToken);
        }
        await changes.Record(w => w.SaveService(service, cancellationToken), cancellationToken);
        return mapper.Map<ServiceNode, ServiceView>(await repository.Service(service.Id, cancellationToken));
    }
}
