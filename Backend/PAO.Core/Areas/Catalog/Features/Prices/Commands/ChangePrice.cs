using FluentValidation;
using PAO.Core.Areas.Catalog.Repositories;
using PAO.Core.Areas.Catalog.Services;
using PAO.Infrastructure.Data;
using PAO.Lib.Areas.Catalog;
using PAO.Lib.Mapping;
using PAO.Lib.Mediator;

namespace PAO.Core.Areas.Catalog.Features.Prices.Commands;

/// <summary>
/// Makes `Amount` the sub-service's current price. Prices are immutable versions: bookings
/// keep the version they copied (PRD §4).
/// </summary>
public sealed record ChangePrice(Guid SubServiceId, long Amount, Guid ActorId) : ICommand<PriceVersionView>;

/// <summary>No negative prices.</summary>
public sealed class ChangePriceValidator : AbstractValidator<ChangePrice>
{
    /// <summary>Declares the rules.</summary>
    public ChangePriceValidator() =>
        RuleFor(r => r.Amount).Must(CatalogRules.IsValidPrice).WithMessage(CatalogReasons.PriceNegative);
}

/// <summary>Inserts the version, publishes `PriceChanged` and bumps the catalog version.</summary>
public sealed class ChangePriceHandler(CatalogRepository repository, CatalogChanges changes, IIdGenerator ids, IClock clock, IMapper mapper)
    : IRequestHandler<ChangePrice, PriceVersionView>
{
    /// <inheritdoc />
    public async Task<PriceVersionView> Handle(ChangePrice request, CancellationToken cancellationToken)
    {
        await repository.SubService(request.SubServiceId, cancellationToken);
        var price = new PriceVersionInfo
        {
            Id = ids.NewId(),
            SubServiceId = request.SubServiceId,
            Amount = request.Amount,
            EffectiveFrom = clock.Now,
            CreatedBy = request.ActorId,
        };
        await changes.Record(
            async w =>
            {
                await w.AddPrice(price, cancellationToken);
                await w.Publish(request.SubServiceId.ToString(), new PriceChanged
                {
                    SubServiceId = request.SubServiceId,
                    PriceVersionId = price.Id,
                    AmountPaisa = request.Amount,
                    ActorId = request.ActorId,
                }, cancellationToken);
            },
            cancellationToken);
        return mapper.Map<PriceVersionInfo, PriceVersionView>(price);
    }
}
