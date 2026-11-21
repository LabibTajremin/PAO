using FluentValidation;
using PAO.Core.Areas.Catalog.Repositories;
using PAO.Core.Areas.Catalog.Services;
using PAO.Infrastructure.Data;
using PAO.Lib.Areas.Catalog;
using PAO.Lib.Mapping;
using PAO.Lib.Mediator;

namespace PAO.Core.Areas.Catalog.Features.ManageCatalog.Commands;

/// <summary>Adds a sub-service with its first price, set by `ActorId`.</summary>
public sealed record CreateSubService(SubServiceInput Input, Guid ActorId) : ICommand<SubServiceView>;

/// <summary>Edits a sub-service; its price changes only through a new price version.</summary>
public sealed record UpdateSubService(Guid Id, SubServiceInput Input) : ICommand<SubServiceView>;

/// <summary>A creation needs a valid item and a first price that is not negative.</summary>
public sealed class CreateSubServiceValidator : AbstractValidator<CreateSubService>
{
    /// <summary>Declares the rules.</summary>
    public CreateSubServiceValidator()
    {
        RuleFor(r => r.Input).Must(SubServiceRules.Valid).WithMessage(CatalogReasons.Invalid);
        RuleFor(r => r.Input.InitialPrice).Must(p => p is { } amount && CatalogRules.IsValidPrice(amount))
            .WithMessage(CatalogReasons.PriceNegative).OverridePropertyName("amount");
    }
}

/// <summary>An update needs a valid item.</summary>
public sealed class UpdateSubServiceValidator : AbstractValidator<UpdateSubService>
{
    /// <summary>Declares the rules.</summary>
    public UpdateSubServiceValidator() => RuleFor(r => r.Input).Must(SubServiceRules.Valid).WithMessage(CatalogReasons.Invalid);
}

/// <summary>The sub-service rules both validators apply.</summary>
public static class SubServiceRules
{
    /// <summary>Names, a known unit and a positive maximum.</summary>
    public static bool Valid(SubServiceInput input) => CatalogRules.IsValidSubService(input.Name, input.Unit, input.MaxQuantity ?? 1);
}

/// <summary>Creates the sub-service and its first price version together.</summary>
public sealed class CreateSubServiceHandler(CatalogRepository repository, CatalogChanges changes, IIdGenerator ids, IClock clock, IMapper mapper)
    : IRequestHandler<CreateSubService, SubServiceView>
{
    /// <inheritdoc />
    public async Task<SubServiceView> Handle(CreateSubService request, CancellationToken cancellationToken)
    {
        await repository.Service(request.Input.ServiceId, cancellationToken);
        var sub = mapper.Map<(Guid, SubServiceInput), SubServiceNode>((ids.NewId(), request.Input));
        var price = new PriceVersionInfo
        {
            Id = ids.NewId(),
            SubServiceId = sub.Id,
            Amount = request.Input.InitialPrice!.Value,
            EffectiveFrom = clock.Now,
            CreatedBy = request.ActorId,
        };
        await changes.Record(
            async w =>
            {
                await w.SaveSubService(sub, cancellationToken);
                await w.AddPrice(price, cancellationToken);
            },
            cancellationToken);
        return mapper.Map<SubServiceNode, SubServiceView>(await repository.SubService(sub.Id, cancellationToken));
    }
}

/// <summary>Saves the edited sub-service and bumps the catalog version.</summary>
public sealed class UpdateSubServiceHandler(CatalogRepository repository, CatalogChanges changes, IMapper mapper)
    : IRequestHandler<UpdateSubService, SubServiceView>
{
    /// <inheritdoc />
    public async Task<SubServiceView> Handle(UpdateSubService request, CancellationToken cancellationToken)
    {
        await repository.Service(request.Input.ServiceId, cancellationToken);
        await repository.SubService(request.Id, cancellationToken);
        var sub = mapper.Map<(Guid, SubServiceInput), SubServiceNode>((request.Id, request.Input));
        await changes.Record(w => w.SaveSubService(sub, cancellationToken), cancellationToken);
        return mapper.Map<SubServiceNode, SubServiceView>(await repository.SubService(sub.Id, cancellationToken));
    }
}
