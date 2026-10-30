using FluentValidation;
using PAO.Core.Areas.Identity.Services;
using PAO.Lib.Mediator;

namespace PAO.Core.Areas.Identity.Features.Logout.Commands;

/// <summary>Signs out this device, or every device of the account.</summary>
public sealed record LogoutCommand(Caller Caller, bool AllDevices) : ICommand;

/// <summary>Validates <see cref="LogoutCommand"/>.</summary>
public sealed class LogoutValidator : AbstractValidator<LogoutCommand>
{
    /// <summary>The rules.</summary>
    public LogoutValidator() => RuleFor(c => c.Caller).NotNull();
}

/// <summary>Handles <see cref="LogoutCommand"/>.</summary>
public sealed class LogoutHandler(Sessions sessions) : IRequestHandler<LogoutCommand, Unit>
{
    /// <inheritdoc />
    public async Task<Unit> Handle(LogoutCommand request, CancellationToken cancellationToken)
    {
        await sessions.Logout(request.Caller, request.AllDevices);
        return Unit.Value;
    }
}
