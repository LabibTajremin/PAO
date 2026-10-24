using FluentValidation;
using PAO.Core.Areas.Identity.Services;
using PAO.Lib.Areas.Identity;
using PAO.Lib.Mapping;
using PAO.Lib.Mediator;

namespace PAO.Core.Areas.Identity.Features.RefreshToken.Commands;

/// <summary>
/// Rotates a refresh token. Mobile apps send it in the body; the admin web app relies on
/// its cookie (`FromCookie`) and gets the new one back as a cookie, not in the body.
/// </summary>
public sealed record RefreshTokenCommand(string Token, bool FromCookie) : ICommand<CookieSession>;

/// <summary>Validates <see cref="RefreshTokenCommand"/>; an empty token is refused by the rotation itself.</summary>
public sealed class RefreshTokenValidator : AbstractValidator<RefreshTokenCommand>
{
    /// <summary>The rules.</summary>
    public RefreshTokenValidator() => RuleFor(c => c.Token).NotNull();
}

/// <summary>Handles <see cref="RefreshTokenCommand"/>.</summary>
public sealed class RefreshTokenHandler(Sessions sessions, IMapper mapper) : IRequestHandler<RefreshTokenCommand, CookieSession>
{
    /// <inheritdoc />
    public async Task<CookieSession> Handle(RefreshTokenCommand request, CancellationToken cancellationToken)
    {
        var session = await sessions.Refresh(request.Token, cancellationToken);
        return new CookieSession(mapper.Map<TokenPairResult, TokenPairView>(new TokenPairResult(session, !request.FromCookie)), session.RefreshToken);
    }
}
