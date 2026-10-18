using PAO.Core.Areas.Identity.Repositories;
using PAO.Infrastructure.Crypto;
using PAO.Infrastructure.Data;
using PAO.Lib.Areas.Identity;
using PAO.Lib.Errors;

namespace PAO.Core.Areas.Identity.Services;

/// <summary>The signed-in device making a request.</summary>
public sealed record Caller(Guid AccountId, Guid SessionId, string TokenId, DateTimeOffset ExpiresAt);

/// <summary>
/// Sessions are refresh-token families in Redis with short-lived access tokens; ending
/// one also denylists its live access token (02-architecture §5).
/// </summary>
public sealed class Sessions(IIdentityRepository repository, ISessionStore families, IAccessTokens tokens, IIdGenerator ids)
{
    /// <summary>Starts a new refresh-token family for the device.</summary>
    public Task<SessionResult> Open(AccountRecord account, string app, bool isNewAccount = false) =>
        Issue(account, new Family { Id = ids.NewId(), AccountId = account.Id, App = app }, isNewAccount);

    /// <summary>
    /// Exchanges a refresh token for a new pair. Presenting an already rotated token
    /// revokes the whole family: someone else has a copy.
    /// </summary>
    public async Task<SessionResult> Refresh(string token, CancellationToken cancellationToken)
    {
        var parsed = IdentityRules.ParseRefreshToken(token) ?? throw new DomainException(IdentityReasons.RefreshInvalid);
        var family = await families.Get(parsed.FamilyId);
        if (!IdentityRules.FamilyMatches(family.CurrentHash, RandomSecrets.Sha256Hex(parsed.Secret)))
        {
            return await EndRefusing(family, IdentityReasons.RefreshReused);
        }
        var account = await repository.AccountById(family.AccountId, cancellationToken);
        if (IdentityRules.SignInRefusal(account) is { } refusal)
        {
            return await EndRefusing(family, refusal);
        }
        return await Issue(account, family, false);
    }

    /// <summary>Ends the caller's session, or every session of the account.</summary>
    public async Task Logout(Caller caller, bool allDevices)
    {
        await tokens.Revoke(caller.TokenId, caller.ExpiresAt);
        if (allDevices)
        {
            await RevokeAll(caller.AccountId);
            return;
        }
        Family family;
        try
        {
            family = await families.Get(caller.SessionId);
        }
        catch (DomainException error) when (error.Reason == IdentityReasons.RefreshInvalid)
        {
            return;
        }
        await End(family);
    }

    /// <summary>Ends every session of an account (ban, suspension, deletion, role change).</summary>
    public async Task RevokeAll(Guid accountId)
    {
        foreach (var family in await families.ListForAccount(accountId))
        {
            await End(family);
        }
    }

    // Ends the family and refuses; a failure to end it rides along as the cause.
    private async Task<SessionResult> EndRefusing(Family family, string reason)
    {
        Exception? cause = null;
        try
        {
            await End(family);
        }
        catch (Exception error)
        {
            cause = error;
        }
        throw new DomainException(reason, cause);
    }

    private async Task<SessionResult> Issue(AccountRecord account, Family family, bool isNewAccount)
    {
        var (token, claims) = await tokens.Sign(account, family.Id);
        var secret = RandomSecrets.Token(32);
        var rotated = family with
        {
            CurrentHash = RandomSecrets.Sha256Hex(secret),
            AccessTokenId = claims.TokenId,
            AccessExpiresAt = claims.ExpiresAt,
        };
        await families.Save(rotated, IdentityRules.RefreshTtl);
        return new SessionResult
        {
            AccessToken = token,
            RefreshToken = IdentityRules.FormatRefreshToken(family.Id, secret),
            ExpiresInSeconds = (int)IdentityRules.AccessTtl.TotalSeconds,
            Account = account,
            IsNewAccount = isNewAccount,
        };
    }

    private async Task End(Family family)
    {
        await tokens.Revoke(family.AccessTokenId, family.AccessExpiresAt);
        await families.Delete(family);
    }
}
