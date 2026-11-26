using PAO.Infrastructure.Crypto;
using PAO.Infrastructure.Data;
using PAO.Infrastructure.Rbac;
using PAO.Infrastructure.Redis;
using PAO.Lib.Areas.Identity;

namespace PAO.Core.Areas.Identity.Services;

/// <summary>Signs and revokes access tokens.</summary>
public interface IAccessTokens
{
    /// <summary>Signs a token for the account on the session (refresh family) `sessionId`.</summary>
    Task<(string Token, AccessClaims Claims)> Sign(AccountRecord account, Guid sessionId);

    /// <summary>Revokes the token `tokenId`, which expires at `expiresAt`.</summary>
    Task Revoke(string tokenId, DateTimeOffset expiresAt);
}

/// <summary>
/// Signs access tokens at the current RBAC version, so a role change outdates them, and
/// revokes live ones until they would have expired.
/// </summary>
public sealed class AccessTokens(TokenSigner signer, RbacChecker rbac, Denylist denylist, IClock clock) : IAccessTokens
{
    /// <inheritdoc />
    public async Task<(string Token, AccessClaims Claims)> Sign(AccountRecord account, Guid sessionId)
    {
        var version = await rbac.Version();
        return signer.Sign(new TokenRequest(account.Id.ToString(), account.Roles, sessionId.ToString(), version));
    }

    /// <inheritdoc />
    public Task Revoke(string tokenId, DateTimeOffset expiresAt) => denylist.Deny(tokenId, expiresAt - clock.Now);
}

/// <summary>Reads and invalidates the RBAC grants.</summary>
public interface IRbacGrants
{
    /// <summary>The union of the roles' permissions and screens.</summary>
    Task<Grants> Of(IReadOnlyCollection<string> roles, CancellationToken cancellationToken);

    /// <summary>Invalidates every cached grant after a role change.</summary>
    Task BumpVersion();
}

/// <summary>The <see cref="IRbacGrants"/> of the platform's <see cref="RbacChecker"/>.</summary>
public sealed class RbacGrants(RbacChecker rbac) : IRbacGrants
{
    /// <inheritdoc />
    public Task<Grants> Of(IReadOnlyCollection<string> roles, CancellationToken cancellationToken) => rbac.GrantsOf(roles, cancellationToken);

    /// <inheritdoc />
    public Task BumpVersion() => rbac.BumpVersion();
}
