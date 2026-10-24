using FluentValidation;
using PAO.Core.Areas.Identity.Repositories;
using PAO.Core.Areas.Identity.Services;
using PAO.Infrastructure.Crypto;
using PAO.Lib.Errors;
using PAO.Lib.Mediator;

namespace PAO.Core.Areas.Identity.Features.ChangeAdminPassword.Commands;

/// <summary>Replaces the temporary or current admin password (A-01).</summary>
public sealed record ChangeAdminPasswordCommand(Guid AccountId, string CurrentPassword, string NewPassword) : ICommand;

/// <summary>Validates <see cref="ChangeAdminPasswordCommand"/>; strength is a business rule of the handler.</summary>
public sealed class ChangeAdminPasswordValidator : AbstractValidator<ChangeAdminPasswordCommand>
{
    /// <summary>The rules.</summary>
    public ChangeAdminPasswordValidator() => RuleFor(c => c.NewPassword).NotNull();
}

/// <summary>Checks the current password, then stores the new one and clears the forced change.</summary>
public sealed class ChangeAdminPasswordHandler(IIdentityRepository repository) : IRequestHandler<ChangeAdminPasswordCommand, Unit>
{
    /// <inheritdoc />
    public async Task<Unit> Handle(ChangeAdminPasswordCommand request, CancellationToken cancellationToken)
    {
        var admin = await repository.AdminById(request.AccountId, cancellationToken);
        if (!await SecretHasher.Verify(request.CurrentPassword, admin.PasswordHash))
        {
            throw new DomainException(IdentityReasons.InvalidCredentials);
        }
        if (!IdentityRules.IsStrongPassword(request.NewPassword))
        {
            throw new DomainException(IdentityReasons.PasswordTooWeak);
        }
        var hash = await SecretHasher.Hash(request.NewPassword, Argon2Params.Password);
        await repository.SaveAdmin(admin with { PasswordHash = hash, MustChangePassword = false }, cancellationToken);
        return Unit.Value;
    }
}
