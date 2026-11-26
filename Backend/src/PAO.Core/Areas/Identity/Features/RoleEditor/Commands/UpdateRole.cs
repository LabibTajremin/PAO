using FluentValidation;
using PAO.Core.Areas.Identity.Repositories;
using PAO.Core.Areas.Identity.Services;
using PAO.Lib.Areas.Identity;
using PAO.Lib.Errors;
using PAO.Lib.Mapping;
using PAO.Lib.Mediator;

namespace PAO.Core.Areas.Identity.Features.RoleEditor.Commands;

/// <summary>Replaces a role's permissions and screens (A-10).</summary>
public sealed record UpdateRoleCommand(string Role, IReadOnlyList<string> Permissions, IReadOnlyList<string> Screens) : ICommand<RoleDefinitionView>;

/// <summary>Validates <see cref="UpdateRoleCommand"/>; unknown names are a business rule.</summary>
public sealed class UpdateRoleValidator : AbstractValidator<UpdateRoleCommand>
{
    /// <summary>The rules.</summary>
    public UpdateRoleValidator() => RuleFor(c => c.Role).NotEmpty();
}

/// <summary>Saves the grants and bumps the RBAC version so every cached grant refreshes (02-architecture §6).</summary>
public sealed class UpdateRoleHandler(IIdentityRepository repository, IRbacGrants rbac, IMapper mapper) : IRequestHandler<UpdateRoleCommand, RoleDefinitionView>
{
    /// <inheritdoc />
    public async Task<RoleDefinitionView> Handle(UpdateRoleCommand request, CancellationToken cancellationToken)
    {
        var roles = await repository.ListRoles(cancellationToken);
        var (permissions, screens) = await repository.Catalogue(cancellationToken);
        var valid = roles.Contains(request.Role) && request.Permissions.All(permissions.Contains) && request.Screens.All(screens.Contains);
        if (!valid)
        {
            throw new DomainException(IdentityReasons.RoleInvalid);
        }
        var definition = new RoleDefinitionRecord(request.Role, request.Permissions, request.Screens);
        await repository.ReplaceRole(definition, cancellationToken);
        await rbac.BumpVersion();
        return mapper.Map<RoleDefinitionRecord, RoleDefinitionView>(definition);
    }
}
