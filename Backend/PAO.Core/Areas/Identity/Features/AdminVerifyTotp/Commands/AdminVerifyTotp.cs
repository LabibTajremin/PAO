using FluentValidation;
using PAO.Core.Areas.Identity.Repositories;
using PAO.Core.Areas.Identity.Services;
using PAO.Infrastructure.Crypto;
using PAO.Infrastructure.Data;
using PAO.Lib.Areas.Identity;
using PAO.Lib.Errors;
using PAO.Lib.Mapping;
using PAO.Lib.Mediator;
using PAO.Lib.Validation;

namespace PAO.Core.Areas.Identity.Features.AdminVerifyTotp.Commands;

/// <summary>Admin step 2 (A-01): the authenticator code completes the login; the refresh token goes in a cookie.</summary>
public sealed record AdminVerifyTotpCommand(string ChallengeId, string Code) : ICommand<CookieSession>;

/// <summary>Validates <see cref="AdminVerifyTotpCommand"/>.</summary>
public sealed class AdminVerifyTotpValidator : AbstractValidator<AdminVerifyTotpCommand>
{
    /// <summary>The rules.</summary>
    public AdminVerifyTotpValidator() => RuleFor(c => c.ChallengeId).Uuid();
}

/// <summary>
/// Completes a login with an authenticator code. On the first login the code confirms
/// enrolment and the new secret is saved; wrong codes count against the challenge.
/// </summary>
public sealed class AdminVerifyTotpHandler(IIdentityRepository repository, IChallengeStore challenges, Sessions sessions, IClock clock, IMapper mapper)
    : IRequestHandler<AdminVerifyTotpCommand, CookieSession>
{
    /// <inheritdoc />
    public async Task<CookieSession> Handle(AdminVerifyTotpCommand request, CancellationToken cancellationToken)
    {
        var challenge = await challenges.Get(Guid.Parse(request.ChallengeId));
        var admin = await repository.AdminById(challenge.AdminId, cancellationToken);
        var secret = challenge.EnrolSecret.Length == 0 ? admin.TotpSecret : challenge.EnrolSecret;
        if (!Totp.Validate(request.Code, secret, clock.Now))
        {
            await Fail(challenge);
        }
        await challenges.Delete(challenge.Id);
        await repository.SaveAdmin(admin with { TotpSecret = secret, TotpEnrolled = true, LastLoginAt = clock.Now }, cancellationToken);
        var session = await sessions.Open(admin, "admin");
        return new CookieSession(mapper.Map<TokenPairResult, TokenPairView>(new TokenPairResult(session, false)), session.RefreshToken);
    }

    private async Task Fail(Challenge challenge)
    {
        var attempts = challenge.Attempts + 1;
        if (attempts >= IdentityRules.ChallengeAttempts)
        {
            await challenges.Delete(challenge.Id);
            throw new DomainException(IdentityReasons.ChallengeExpired);
        }
        await challenges.Save(challenge with { Attempts = attempts }, IdentityRules.ChallengeTtl);
        throw new DomainException(IdentityReasons.TotpInvalid);
    }
}
