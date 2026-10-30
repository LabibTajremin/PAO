using FluentValidation;
using PAO.Core.Areas.Identity.Repositories;
using PAO.Core.Areas.Identity.Services;
using PAO.Lib.Areas.Identity;
using PAO.Lib.Errors;
using PAO.Lib.Mapping;
using PAO.Lib.Mediator;

namespace PAO.Core.Areas.Identity.Features.AdminUsers.Commands;

/// <summary>Invites an admin with a temporary password and forced TOTP enrolment (A-10).</summary>
public sealed record InviteAdminUserCommand(string Email, string Name, IReadOnlyList<string> Roles) : ICommand<AdminUserInvitedView>;

/// <summary>Validates <see cref="InviteAdminUserCommand"/>; whether the roles are admin roles is a business rule.</summary>
public sealed class InviteAdminUserValidator : AbstractValidator<InviteAdminUserCommand>
{
    /// <summary>The rules.</summary>
    public InviteAdminUserValidator() => RuleFor(c => c.Email).NotEmpty();
}

/// <summary>Handles <see cref="InviteAdminUserCommand"/>.</summary>
public sealed class InviteAdminUserHandler(Services.AdminUsers admins, IMapper mapper) : IRequestHandler<InviteAdminUserCommand, AdminUserInvitedView>
{
    /// <inheritdoc />
    public async Task<AdminUserInvitedView> Handle(InviteAdminUserCommand request, CancellationToken cancellationToken) =>
        mapper.Map<InvitedAdmin, AdminUserInvitedView>(await admins.Create(request.Email, request.Name, request.Roles, cancellationToken));
}

/// <summary>Changes an admin's roles and/or active flag; null fields stay as they are.</summary>
public sealed record UpdateAdminUserCommand(Guid AdminId, IReadOnlyList<string>? Roles, bool? Active) : ICommand<AdminUserView>;

/// <summary>Validates <see cref="UpdateAdminUserCommand"/>.</summary>
public sealed class UpdateAdminUserValidator : AbstractValidator<UpdateAdminUserCommand>
{
    /// <summary>The rules.</summary>
    public UpdateAdminUserValidator() => RuleFor(c => c.AdminId).NotEmpty();
}

/// <summary>Changes the admin and ends their sessions, so new rights apply at once.</summary>
public sealed class UpdateAdminUserHandler(IIdentityRepository repository, Sessions sessions, IMapper mapper) : IRequestHandler<UpdateAdminUserCommand, AdminUserView>
{
    /// <inheritdoc />
    public async Task<AdminUserView> Handle(UpdateAdminUserCommand request, CancellationToken cancellationToken)
    {
        if (request.Roles is not null && !IdentityRules.IsAdminRoleSet(request.Roles))
        {
            throw new DomainException(IdentityReasons.RoleInvalid);
        }
        var current = await repository.AdminById(request.AdminId, cancellationToken);
        var admin = current with { Roles = request.Roles ?? current.Roles, Active = request.Active ?? current.Active };
        if (request.Roles is not null)
        {
            await repository.SetRoles(admin.Id, admin.Roles, cancellationToken);
        }
        await repository.SaveAdmin(admin, cancellationToken);
        await sessions.RevokeAll(admin.Id);
        return mapper.Map<AdminRecord, AdminUserView>(admin);
    }
}

/// <summary>Creates a seed file's demo admin once, with a known password (`migrate seed`, dev and staging).</summary>
public sealed record EnsureSeedAdminCommand(string Email, string Name, IReadOnlyList<string> Roles, string Password) : ICommand;

/// <summary>Validates <see cref="EnsureSeedAdminCommand"/>.</summary>
public sealed class EnsureSeedAdminValidator : AbstractValidator<EnsureSeedAdminCommand>
{
    /// <summary>The rules.</summary>
    public EnsureSeedAdminValidator() => RuleFor(c => c.Password).NotEmpty();
}

/// <summary>Handles <see cref="EnsureSeedAdminCommand"/>.</summary>
public sealed class EnsureSeedAdminHandler(Services.AdminUsers admins) : IRequestHandler<EnsureSeedAdminCommand, Unit>
{
    /// <inheritdoc />
    public async Task<Unit> Handle(EnsureSeedAdminCommand request, CancellationToken cancellationToken)
    {
        await admins.Ensure(request.Email, request.Name, request.Roles, request.Password, cancellationToken);
        return Unit.Value;
    }
}

/// <summary>
/// Creates the first production super admin (`migrate create-admin`) with an operator-chosen
/// password; an existing email is left untouched. The result says whether it was created.
/// </summary>
public sealed record CreateSuperAdminCommand(string Email, string Name, string Password) : ICommand<bool>;

/// <summary>Validates <see cref="CreateSuperAdminCommand"/>: a long password, since it guards every permission.</summary>
public sealed class CreateSuperAdminValidator : AbstractValidator<CreateSuperAdminCommand>
{
    /// <summary>The shortest accepted password.</summary>
    public const int MinimumPasswordLength = 12;

    /// <summary>The rules.</summary>
    public CreateSuperAdminValidator()
    {
        RuleFor(c => c.Email).NotEmpty().EmailAddress();
        RuleFor(c => c.Name).NotEmpty();
        RuleFor(c => c.Password).MinimumLength(MinimumPasswordLength);
    }
}

/// <summary>Handles <see cref="CreateSuperAdminCommand"/>.</summary>
public sealed class CreateSuperAdminHandler(Services.AdminUsers admins) : IRequestHandler<CreateSuperAdminCommand, bool>
{
    /// <inheritdoc />
    public Task<bool> Handle(CreateSuperAdminCommand request, CancellationToken cancellationToken) =>
        admins.Ensure(request.Email, request.Name, [Roles.SuperAdmin], request.Password, cancellationToken);
}
