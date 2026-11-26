using FluentValidation;
using PAO.Core.Areas.Identity.Repositories;
using PAO.Core.Areas.Identity.Services;
using PAO.Lib.Areas.Identity;
using PAO.Lib.Errors;
using PAO.Lib.Mediator;

namespace PAO.Core.Areas.Identity.Features.DeleteMe.Commands;

/// <summary>Erases the caller's account after re-confirming with a `delete_account` code (PRD §11).</summary>
public sealed record DeleteMeCommand(Guid AccountId, string Code) : ICommand;

/// <summary>Validates <see cref="DeleteMeCommand"/>.</summary>
public sealed class DeleteMeValidator : AbstractValidator<DeleteMeCommand>
{
    /// <summary>The rules.</summary>
    public DeleteMeValidator() => RuleFor(c => c.Code).NotNull();
}

/// <summary>
/// Sessions end, personal data is anonymised and AccountDeleted tells the other areas to
/// erase theirs.
/// </summary>
public sealed class DeleteMeHandler(IIdentityRepository repository, PhoneCodes codes, Sessions sessions) : IRequestHandler<DeleteMeCommand, Unit>
{
    /// <inheritdoc />
    public async Task<Unit> Handle(DeleteMeCommand request, CancellationToken cancellationToken)
    {
        var account = await repository.AccountById(request.AccountId, cancellationToken);
        if (account.Phone.Length == 0)
        {
            throw new DomainException(IdentityReasons.AccountDeleted);
        }
        await codes.Check(CodePurpose.DeleteAccount, account.Phone, request.Code);
        try
        {
            await repository.SetRoles(account.Id, [], cancellationToken);
            await repository.AnonymiseAccount(account.Id, cancellationToken);
            await repository.Publish(account.Id, new AccountDeleted { AccountId = account.Id }, cancellationToken);
        }
        finally
        {
            // Sessions end even when erasing failed: the person asked to be signed out.
            await sessions.RevokeAll(account.Id);
        }
        return Unit.Value;
    }
}
