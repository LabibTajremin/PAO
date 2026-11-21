using FluentValidation;
using PAO.Core.Areas.Catalog.Repositories;
using PAO.Core.Areas.Catalog.Services;
using PAO.Infrastructure.Data;
using PAO.Lib.Areas.Catalog;
using PAO.Lib.Errors;
using PAO.Lib.Mapping;
using PAO.Lib.Mediator;

namespace PAO.Core.Areas.Catalog.Features.ManageCatalog.Commands;

/// <summary>Creates a category, or updates the one with `Id` (A-02).</summary>
public sealed record SaveCategory(Guid? Id, CategoryInput Input) : ICommand<CategoryView>;

/// <summary>Both names, a library icon and, if any, an icon we stored.</summary>
public sealed class SaveCategoryValidator : AbstractValidator<SaveCategory>
{
    /// <summary>Declares the rules.</summary>
    public SaveCategoryValidator(IconAddress icons)
    {
        RuleFor(r => r.Input).Must(i => CatalogRules.IsValidCategory(i.Name, i.IconKey)).WithMessage(CatalogReasons.Invalid);
        RuleFor(r => r.Input.IconUrl).Must(icons.IsStoredOrAbsent).WithMessage(CatalogReasons.IconNotStored);
    }
}

/// <summary>Saves the category and bumps the catalog version.</summary>
public sealed class SaveCategoryHandler(CatalogRepository repository, CatalogChanges changes, IIdGenerator ids, IMapper mapper)
    : IRequestHandler<SaveCategory, CategoryView>
{
    /// <inheritdoc />
    public async Task<CategoryView> Handle(SaveCategory request, CancellationToken cancellationToken)
    {
        if (request.Id is { } id && !await repository.CategoryExists(id, cancellationToken))
        {
            throw new DomainException(CatalogReasons.NotFound);
        }
        var category = mapper.Map<(Guid, CategoryInput), CategoryNode>((request.Id ?? ids.NewId(), request.Input));
        await changes.Record(w => w.SaveCategory(category, cancellationToken), cancellationToken);
        return mapper.Map<CategoryNode, CategoryView>(category);
    }
}
