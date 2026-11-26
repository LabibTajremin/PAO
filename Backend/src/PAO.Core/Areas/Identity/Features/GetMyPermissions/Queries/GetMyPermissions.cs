using FluentValidation;
using PAO.Core.Areas.Identity.Repositories;
using PAO.Core.Areas.Identity.Services;
using PAO.Lib.Areas.Identity;
using PAO.Lib.Mapping;
using PAO.Lib.Mediator;

namespace PAO.Core.Areas.Identity.Features.GetMyPermissions.Queries;

/// <summary>Roles, permissions and screen ids of the signed-in account, for route guards.</summary>
public sealed record GetMyPermissionsQuery(Guid AccountId) : IQuery<MyPermissionsView>;

/// <summary>Validates <see cref="GetMyPermissionsQuery"/>.</summary>
public sealed class GetMyPermissionsValidator : AbstractValidator<GetMyPermissionsQuery>
{
    /// <summary>The rules.</summary>
    public GetMyPermissionsValidator() => RuleFor(q => q.AccountId).NotEmpty();
}

/// <summary>Resolves the grants; a merchant below Level 1 sees only the onboarding and verification screens (PRD §8.5).</summary>
public sealed class GetMyPermissionsHandler(IIdentityRepository repository, IRbacGrants rbac, ILevelReader levels, IMapper mapper)
    : IRequestHandler<GetMyPermissionsQuery, MyPermissionsView>
{
    /// <inheritdoc />
    public async Task<MyPermissionsView> Handle(GetMyPermissionsQuery request, CancellationToken cancellationToken)
    {
        var account = await repository.AccountById(request.AccountId, cancellationToken);
        var grants = await rbac.Of(account.Roles, cancellationToken);
        var view = new PermissionsResult(account.Roles, grants.Permissions, grants.Screens, false);
        if (account.Roles.Contains(Roles.Provider) && await levels.GetLevel(account.Id, cancellationToken) < 1)
        {
            var screens = grants.Screens.Where(id => !id.StartsWith('M') || IdentityRules.ProviderGateScreens.Contains(id)).ToList();
            view = view with { Screens = screens, ProviderGate = true };
        }
        return mapper.Map<PermissionsResult, MyPermissionsView>(view);
    }
}
