using System.Text;
using System.Text.Json;
using Microsoft.AspNetCore.WebUtilities;
using Org.BouncyCastle.Crypto.Parameters;
using PAO.Infrastructure.Data;

namespace PAO.Infrastructure.Crypto;

/// <summary>
/// Checks access tokens against the current and previous public keys (kid → key), so keys
/// can rotate without signing everyone out. The checks are those jose runs:
/// EdDSA only, known kid, valid signature, `iss` = pao, numeric `exp` in the future.
/// </summary>
public sealed class TokenVerifier(IReadOnlyDictionary<string, Ed25519PublicKeyParameters> keys, IClock clock)
{
    /// <summary>Returns the token's claims or throws <see cref="TokenExpiredException"/> / <see cref="TokenInvalidException"/>.</summary>
    public AccessClaims Verify(string token)
    {
        var parts = token.Split('.');
        if (parts.Length != 3)
        {
            throw new TokenInvalidException("not a compact JWS");
        }
        using var header = ParseSegment(parts[0], "header");
        CheckHeaderAndSignature(header.RootElement, parts);
        using var payload = ParseSegment(parts[1], "payload");
        CheckTimes(payload.RootElement);
        return ToClaims(payload.RootElement);
    }

    private void CheckHeaderAndSignature(JsonElement header, string[] parts)
    {
        if (Text(header, "alg") != "EdDSA" || header.TryGetProperty("crit", out _))
        {
            throw new TokenInvalidException("unsupported header");
        }
        if (Text(header, "kid") is not { } kid || !keys.TryGetValue(kid, out var key))
        {
            throw new TokenInvalidException("unknown key id");
        }
        var signed = Encoding.ASCII.GetBytes(parts[0] + "." + parts[1]);
        if (!Ed25519Keys.Verify(key, signed, Decode(parts[2], "signature")))
        {
            throw new TokenInvalidException("signature verification failed");
        }
    }

    private void CheckTimes(JsonElement payload)
    {
        var now = clock.Now.ToUnixTimeSeconds();
        if (!payload.TryGetProperty("exp", out var exp))
        {
            throw new TokenInvalidException("missing exp");
        }
        if (Text(payload, "iss") != "pao")
        {
            throw new TokenInvalidException("unexpected iss");
        }
        if (payload.TryGetProperty("iat", out var iat) && iat.ValueKind != JsonValueKind.Number)
        {
            throw new TokenInvalidException("iat is not a number");
        }
        if (payload.TryGetProperty("nbf", out var nbf) && (nbf.ValueKind != JsonValueKind.Number || nbf.GetDouble() > now))
        {
            throw new TokenInvalidException("not yet valid");
        }
        if (exp.ValueKind != JsonValueKind.Number)
        {
            throw new TokenInvalidException("exp is not a number");
        }
        if (exp.GetDouble() <= now)
        {
            throw new TokenExpiredException();
        }
    }

    private static AccessClaims ToClaims(JsonElement p)
    {
        var sub = Text(p, "sub");
        var sessionId = p.TryGetProperty("sid", out _) ? Text(p, "sid") : UuidText.Nil;
        if (!UuidText.IsValid(sub) || !UuidText.IsValid(sessionId)
            || !p.TryGetProperty("roles", out var roles) || roles.ValueKind != JsonValueKind.Array
            || roles.EnumerateArray().Any(r => r.ValueKind != JsonValueKind.String))
        {
            throw new TokenInvalidException("claims do not describe an account");
        }
        return new AccessClaims
        {
            Subject = sub!,
            Roles = [.. roles.EnumerateArray().Select(r => r.GetString()!)],
            TokenId = Text(p, "jti") ?? string.Empty,
            SessionId = sessionId!,
            Version = p.TryGetProperty("ver", out var ver) && ver.ValueKind == JsonValueKind.Number ? (long)ver.GetDouble() : 0,
            ExpiresAt = DateTimeOffset.FromUnixTimeSeconds((long)p.GetProperty("exp").GetDouble()),
        };
    }

    private static string? Text(JsonElement element, string name) =>
        element.TryGetProperty(name, out var value) && value.ValueKind == JsonValueKind.String ? value.GetString() : null;

    private static JsonDocument ParseSegment(string segment, string what)
    {
        try
        {
            var document = JsonDocument.Parse(Decode(segment, what));
            if (document.RootElement.ValueKind == JsonValueKind.Object)
            {
                return document;
            }
            document.Dispose();
        }
        catch (JsonException)
        {
            // Reported below as a malformed token, like any other unreadable segment.
        }
        throw new TokenInvalidException($"{what} is not a JSON object");
    }

    private static byte[] Decode(string segment, string what)
    {
        try
        {
            return WebEncoders.Base64UrlDecode(segment);
        }
        catch (FormatException)
        {
            throw new TokenInvalidException($"{what} is not base64url");
        }
    }
}
