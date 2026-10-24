using FluentValidation;
using PAO.Core.Areas.Identity.Services;
using PAO.Lib.Areas.Identity;
using PAO.Lib.Mapping;
using PAO.Lib.Mediator;

namespace PAO.Core.Areas.Identity.Features.SetAccountStatus.Commands;

/// <summary>Suspends, bans or reinstates an account; other areas send it through the shared service (A-05).</summary>
public sealed record SetAccountStatusCommand(SetAccountStatusInput Input) : ICommand<Account>;

/// <summary>Validates <see cref="SetAccountStatusCommand"/>; whether the change is allowed is a business rule.</summary>
public sealed class SetAccountStatusValidator : AbstractValidator<SetAccountStatusCommand>
{
    /// <summary>The rules.</summary>
    public SetAccountStatusValidator() => RuleFor(c => c.Input.AccountId).NotEmpty();
}

/// <summary>Handles <see cref="SetAccountStatusCommand"/>.</summary>
public sealed class SetAccountStatusHandler(AccountStatusChanger changer, IMapper mapper) : IRequestHandler<SetAccountStatusCommand, Account>
{
    /// <inheritdoc />
    public async Task<Account> Handle(SetAccountStatusCommand request, CancellationToken cancellationToken) =>
        mapper.Map<AccountRecord, Account>(await changer.Set(request.Input, cancellationToken));
}
