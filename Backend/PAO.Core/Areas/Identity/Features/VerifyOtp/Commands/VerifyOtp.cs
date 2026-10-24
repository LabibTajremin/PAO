using FluentValidation;
using PAO.Core.Areas.Identity.Services;
using PAO.Lib.Areas.Identity;
using PAO.Lib.Errors;
using PAO.Lib.Mapping;
using PAO.Lib.Mediator;

namespace PAO.Core.Areas.Identity.Features.VerifyOtp.Commands;

/// <summary>Completes a phone sign-in; `App` is `customer` or `partner` (the partner app grants the merchant role).</summary>
public sealed record VerifyOtpCommand(string Phone, string Code, string App) : ICommand<TokenPairView>;

/// <summary>Validates <see cref="VerifyOtpCommand"/>.</summary>
public sealed class VerifyOtpValidator : AbstractValidator<VerifyOtpCommand>
{
    /// <summary>The rules.</summary>
    public VerifyOtpValidator()
    {
        RuleFor(c => c.Code).NotEmpty();
        RuleFor(c => c.App).Must(a => a is "customer" or "partner");
    }
}

/// <summary>
/// Checks the code, creates the account on first sign-in or adds the app's role, and opens
/// a session.
/// </summary>
public sealed class VerifyOtpHandler(PhoneCodes codes, PhoneAccounts accounts, Sessions sessions, IMapper mapper)
    : IRequestHandler<VerifyOtpCommand, TokenPairView>
{
    /// <inheritdoc />
    public async Task<TokenPairView> Handle(VerifyOtpCommand request, CancellationToken cancellationToken)
    {
        var phone = IdentityRules.PhoneOrFail(request.Phone);
        await codes.Check(CodePurpose.Login, phone, request.Code);
        var role = IdentityRules.RoleForApp(request.App);
        var existing = await accounts.Find(phone, cancellationToken);
        var account = existing is null
            ? await accounts.Register(phone, role, cancellationToken)
            : await accounts.AddRole(existing, role, cancellationToken);
        if (IdentityRules.SignInRefusal(account) is { } refusal)
        {
            throw new DomainException(refusal);
        }
        var session = await sessions.Open(account, request.App, existing is null);
        return mapper.Map<TokenPairResult, TokenPairView>(new TokenPairResult(session, true));
    }
}
