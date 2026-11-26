using System.Text.RegularExpressions;

namespace PAO.Infrastructure.Crypto;

/// <summary>The claims of an access token (02-architecture §5).</summary>
public sealed record AccessClaims
{
    /// <summary>The subject.</summary>
    public required string Subject { get; init; }
    /// <summary>The roles.</summary>
    public required IReadOnlyList<string> Roles { get; init; }

    /// <summary>The token id (`jti`), used by the denylist.</summary>
    public required string TokenId { get; init; }

    /// <summary>The refresh-token family (device) the token belongs to (`sid`).</summary>
    public required string SessionId { get; init; }

    /// <summary>The RBAC version the roles were read at (`ver`).</summary>
    public required long Version { get; init; }
    /// <summary>The expires at.</summary>
    public required DateTimeOffset ExpiresAt { get; init; }
}

/// <summary>What the caller decides when signing; the signer fills in the id and expiry.</summary>
public sealed record TokenRequest(string Subject, IReadOnlyList<string> Roles, string? SessionId = null, long Version = 0);

/// <summary>Thrown for a token whose expiry has passed; the API answers TOKEN_EXPIRED.</summary>
public sealed class TokenExpiredException() : Exception("access token expired");

/// <summary>Thrown for a token that is forged, malformed or signed by an unknown key.</summary>
public sealed class TokenInvalidException(string reason) : Exception("access token invalid: " + reason);

/// <summary>UUID text as the `uuid` npm package validated it, so the same tokens pass.</summary>
public static partial class UuidText
{
    /// <summary>The nil UUID, the default session of a token without `sid`.</summary>
    public const string Nil = "00000000-0000-0000-0000-000000000000";

    /// <summary>Reports whether `value` is a UUID string.</summary>
    public static bool IsValid(string? value) => value is not null && Pattern().IsMatch(value);

    [GeneratedRegex("^(?:[0-9a-f]{8}-[0-9a-f]{4}-[1-8][0-9a-f]{3}-[89ab][0-9a-f]{3}-[0-9a-f]{12}|00000000-0000-0000-0000-000000000000|ffffffff-ffff-ffff-ffff-ffffffffffff)$", RegexOptions.IgnoreCase)]
    private static partial Regex Pattern();
}
