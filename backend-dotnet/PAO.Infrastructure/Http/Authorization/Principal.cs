using System.Security.Claims;
using Microsoft.AspNetCore.Http;
using PAO.Infrastructure.Crypto;
using PAO.Infrastructure.Http.Edge;
using PAO.Infrastructure.Http.Errors;

namespace PAO.Infrastructure.Http.Authorization;

/// <summary>The authenticated caller, read from a verified access token.</summary>
public sealed record Principal
{
    public required Guid AccountId { get; init; }
    public required IReadOnlyList<string> Roles { get; init; }

    /// <summary>The access token id (`jti`), for logout and revocation.</summary>
    public required string TokenId { get; init; }

    /// <summary>The refresh-token family (device) the token belongs to.</summary>
    public required string SessionId { get; init; }
    public required DateTimeOffset ExpiresAt { get; init; }

    /// <summary>Reports whether the principal holds `role`.</summary>
    public bool HasRole(string role) => Roles.Contains(role);

    /// <summary>The principal of verified `claims`.</summary>
    public static Principal From(AccessClaims claims) => new()
    {
        AccountId = Guid.Parse(claims.Subject),
        Roles = claims.Roles,
        TokenId = claims.TokenId,
        SessionId = claims.SessionId,
        ExpiresAt = claims.ExpiresAt,
    };

    /// <summary>The same caller as a <see cref="ClaimsPrincipal"/> for framework code.</summary>
    public ClaimsPrincipal ToClaimsPrincipal() => new(new ClaimsIdentity(
        [new Claim("sub", AccountId.ToString()), .. Roles.Select(r => new Claim(ClaimTypes.Role, r))],
        authenticationType: "Bearer"));
}

/// <summary>Reads the caller inside controllers and handlers.</summary>
public static class PrincipalExtensions
{
    /// <summary>The authenticated caller, or 401 if there is none.</summary>
    public static Principal Caller(this HttpContext context) =>
        context.Edge().Principal ?? throw ApiErrors.Unauthenticated;
}
