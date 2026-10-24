using PAO.Core.Areas.Identity.Repositories;
using PAO.Infrastructure.Crypto;
using PAO.Infrastructure.Sms;
using PAO.Lib.Areas.Identity;
using PAO.Lib.Errors;

namespace PAO.Core.Areas.Identity.Services;

/// <summary>
/// How long the caller must wait for another code; the cause of the `identity.rate_limited`
/// <see cref="DomainException"/> a throttled send throws.
/// </summary>
public sealed class CodeRateLimitedException(TimeSpan retryAfter) : Exception("code requested too soon")
{
    /// <summary>How long to wait.</summary>
    public TimeSpan RetryAfter { get; } = retryAfter;
}

/// <summary>
/// Sends and checks one-time codes. A code sent for one purpose never satisfies another
/// (`login`, `delete_account`, `emergency_contact`).
/// </summary>
public sealed class PhoneCodes(IIdentityRepository repository, ICodeStore codes, ISendThrottle throttle, ISmsSender sms)
{
    /// <summary>
    /// Rate-limits, stores the hash of a fresh 6-digit code and texts it; returns the phone.
    /// `clientIp` is null when the server sends on behalf of a signed-in user: those share
    /// no address, so a per-IP window would throttle every merchant at once.
    /// </summary>
    public async Task<string> Send(string rawPhone, string purpose, string? clientIp, CancellationToken cancellationToken)
    {
        var phone = IdentityRules.PhoneOrFail(rawPhone);
        // Banned identities get no login code, so no SMS is paid for (PRD §6.4).
        if (purpose == CodePurpose.Login && await repository.IsPhoneBlocked(phone, cancellationToken))
        {
            throw new DomainException(IdentityReasons.AccountBanned);
        }
        var wait = await throttle.RetryAfter(phone, clientIp);
        if (wait > TimeSpan.Zero)
        {
            throw new DomainException(IdentityReasons.RateLimited, new CodeRateLimitedException(wait));
        }
        var code = RandomSecrets.Digits(IdentityRules.CodeLength);
        await codes.Save(purpose, phone, new StoredCode(await SecretHasher.Hash(code, Argon2Params.Code), 0));
        var message = $"PAO code: {code}. Valid for 5 minutes. Never share it. / আপনার PAO কোড {code}";
        try
        {
            await sms.Send(phone, message, cancellationToken);
        }
        catch (Exception error)
        {
            throw new InvalidOperationException($"send code to {PhoneNumber.Mask(phone)}", error);
        }
        return phone;
    }

    /// <summary>Verifies a code, consuming it on success or lockout.</summary>
    public async Task Check(string purpose, string phone, string code)
    {
        var stored = await codes.Get(purpose, phone);
        var (discard, refusal) = IdentityRules.CheckAttempt(stored.Attempts, await SecretHasher.Verify(code, stored.Hash));
        await (discard ? codes.Delete(purpose, phone) : codes.IncrementAttempts(purpose, phone));
        if (refusal is not null)
        {
            throw new DomainException(refusal);
        }
    }

    /// <summary>Checks a code for a phone someone typed, e.g. an emergency contact's (PRD §6.2).</summary>
    public Task CheckTyped(string rawPhone, string purpose, string code) => Check(purpose, IdentityRules.PhoneOrFail(rawPhone), code);
}
