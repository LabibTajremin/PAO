using FluentValidation;
using PAO.Core.Areas.Identity.Services;
using PAO.Infrastructure.Http.Errors;
using PAO.Lib.Areas.Identity;
using PAO.Lib.Errors;
using PAO.Lib.Mediator;
using PAO.Lib.Validation;

namespace PAO.Core.Areas.Identity.Features.RequestOtp.Commands;

/// <summary>Sends a 6-digit code by SMS (C-01, P-01); `ClientIp` feeds the per-IP window.</summary>
public sealed record RequestOtpCommand(string Phone, string Purpose, string ClientIp) : ICommand<OtpRequestAcceptedView>;

/// <summary>Validates <see cref="RequestOtpCommand"/>.</summary>
public sealed class RequestOtpValidator : AbstractValidator<RequestOtpCommand>
{
    /// <summary>The rules.</summary>
    public RequestOtpValidator()
    {
        RuleFor(c => c.Phone).BangladeshPhone();
        RuleFor(c => c.Purpose).Must(p => p is CodePurpose.Login or CodePurpose.DeleteAccount);
    }
}

/// <summary>
/// Handles <see cref="RequestOtpCommand"/>; a throttled send answers 429 RATE_LIMITED with
/// Retry-After, except inside the resend minute while the code just sent is still live.
/// </summary>
public sealed class RequestOtpHandler(PhoneCodes codes) : IRequestHandler<RequestOtpCommand, OtpRequestAcceptedView>
{
    /// <inheritdoc />
    public async Task<OtpRequestAcceptedView> Handle(RequestOtpCommand request, CancellationToken cancellationToken)
    {
        try
        {
            await codes.Send(request.Phone, request.Purpose, request.ClientIp, cancellationToken);
        }
        catch (DomainException error) when (error.InnerException is CodeRateLimitedException limited)
        {
            // A sleeping server can outlast the app's timeout: the first request still sends,
            // and the user's retry must lead to that code, not a 429 dead end. Nothing is resent.
            if (limited.RetryAfter > IdentityRules.ResendAfter || !await codes.HasLiveCode(request.Phone, request.Purpose))
            {
                throw ApiErrors.RateLimited("RATE_LIMITED", limited.RetryAfter);
            }
            var wait = (int)Math.Ceiling(limited.RetryAfter.TotalSeconds);
            return new OtpRequestAcceptedView((int)(IdentityRules.CodeTtl - IdentityRules.ResendAfter).TotalSeconds + wait, wait);
        }
        return new OtpRequestAcceptedView((int)IdentityRules.CodeTtl.TotalSeconds, (int)IdentityRules.ResendAfter.TotalSeconds);
    }
}
