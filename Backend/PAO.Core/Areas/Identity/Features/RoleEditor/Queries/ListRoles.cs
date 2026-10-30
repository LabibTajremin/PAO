using FluentValidation;
using PAO.Core.Areas.Identity.Repositories;
using PAO.Lib.Areas.Identity;
using PAO.Lib.Mapping;
using PAO.Lib.Mediator;

namespace PAO.Core.Areas.Identity.Features.RoleEditor.Queries;

/// <summary>Every role with its grants and the catalogue to choose from (A-10).</summary>
public sealed record ListRolesQuery : IQuery<RoleListView>;

/// <summary>Validates <see cref="ListRolesQuery"/>; it has no fields.</summary>
public sealed class ListRolesValidator : AbstractValidator<ListRolesQuery>;

/// <summary>Handles <see cref="ListRolesQuery"/> with one read per table.</summary>
public sealed class ListRolesHandler(IIdentityRepository repository, IMapper mapper) : IRequestHandler<ListRolesQuery, RoleListView>
{
    /// <inheritdoc />
    public async Task<RoleListView> Handle(ListRolesQuery request, CancellationToken cancellationToken)
    {
        var grants = await repository.AllGrants(cancellationToken);
        var roles = (await repository.ListRoles(cancellationToken))
            .Select(r => grants.TryGetValue(r, out var g) ? new RoleDefinitionRecord(r, g.Permissions, g.Screens) : new RoleDefinitionRecord(r, [], []))
            .ToList();
        var (permissions, screens) = await repository.Catalogue(cancellationToken);
        return mapper.Map<RoleCatalogue, RoleListView>(new RoleCatalogue(roles, permissions, screens));
    }
}
