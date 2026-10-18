using FluentValidation;
using PAO.Core.Areas.Identity.Repositories;
using PAO.Core.Areas.Identity.Services;
using PAO.Infrastructure.Crypto;
using PAO.Infrastructure.Data;
using PAO.Lib.Areas.Identity;
using PAO.Lib.Errors;
using PAO.Lib.Mapping;
using PAO.Lib.Mediator;

namespace PAO.Core.Areas.Identity.Features.AdminLogin.Commands;

/// <summary>
/// Admin step 1 (A-01): email and password, answering a TOTP challenge. Deliberately not an
/// <see cref="ICommand{TResult}"/>: a refused password must still store the failure count
/// that drives the lockout, so its write may not roll back with the refusal.
/// </summary>
public sealed record AdminLoginRequest(string Email, string Password) : IRequest<AdminLoginChallengeView>;

/// <summary>Validates <see cref="AdminLoginRequest"/>.</summary>
public sealed class AdminLoginValidator : AbstractValidator<AdminLoginRequest>
{
    /// <summary>The rules.</summary>
    public AdminLoginValidator()
    {
        RuleFor(r => r.Email).NotNull();
        RuleFor(r => r.Password).NotNull();
    }
}

/// <summary>Checks email and password and starts the TOTP step; wrong passwords lock out.</summary>
public sealed class AdminLoginHandler(IIdentityRepository repository, IChallengeStore challenges, IClock clock, IIdGenerator ids, IMapper mapper)
    : IRequestHandler<AdminLoginRequest, AdminLoginChallengeView>
{
    /// <inheritdoc />
    public async Task<AdminLoginChallengeView> Handle(AdminLoginRequest request, CancellationToken cancellationToken)
    {
        var admin = await AdminByEmail(request.Email, cancellationToken);
        var now = clock.Now;
        if (IdentityRules.AdminLoginRefusal(admin, now) is { } refusal)
        {
            throw new DomainException(refusal);
        }
        if (!await SecretHasher.Verify(request.Password, admin.PasswordHash))
        {
            await repository.SaveAdmin(IdentityRules.RecordFailure(admin, now), cancellationToken);
            throw new DomainException(IdentityReasons.InvalidCredentials);
        }
        var cleared = IdentityRules.RecordSuccess(admin);
        await repository.SaveAdmin(cleared, cancellationToken);
        return mapper.Map<AdminChallengeResult, AdminLoginChallengeView>(await StartChallenge(cleared));
    }

    private async Task<AdminRecord> AdminByEmail(string email, CancellationToken cancellationToken)
    {
        try
        {
            return await repository.AdminByEmail(email, cancellationToken);
        }
        catch (DomainException error) when (error.Reason == IdentityReasons.AccountNotFound)
        {
            throw new DomainException(IdentityReasons.InvalidCredentials);
        }
    }

    private async Task<AdminChallengeResult> StartChallenge(AdminRecord admin)
    {
        var enrolment = admin.TotpEnrolled ? new TotpEnrolment(string.Empty, string.Empty) : Totp.NewSecret(admin.Email);
        var id = ids.NewId();
        await challenges.Save(new Challenge { Id = id, AdminId = admin.Id, EnrolSecret = enrolment.Secret }, IdentityRules.ChallengeTtl);
        return new AdminChallengeResult
        {
            Id = id,
            EnrolSecret = enrolment.Secret,
            EnrolUrl = enrolment.Url,
            MustChangePassword = admin.MustChangePassword,
            ExpiresInSeconds = (int)IdentityRules.ChallengeTtl.TotalSeconds,
        };
    }
}
