using System.Text;
using System.Text.Json;
using Microsoft.AspNetCore.WebUtilities;
using Org.BouncyCastle.Crypto.Parameters;
using PAO.Infrastructure.Data;

namespace PAO.Infrastructure.Crypto;

/// <summary>The current signing key, its id and how long its tokens live (15 minutes in production).</summary>
public sealed record SigningKey(string KeyId, Ed25519PrivateKeyParameters Key, TimeSpan Ttl);

/// <summary>
/// Issues EdDSA (Ed25519) access tokens: the same header, claim names and claim order as
/// the NestJS backend (jose), so either backend accepts the other's tokens.
/// </summary>
public sealed class TokenSigner(SigningKey signing, IClock clock, IIdGenerator ids)
{
    /// <summary>Signs a token and returns it with the claims it carries.</summary>
    public (string Token, AccessClaims Claims) Sign(TokenRequest request)
    {
        var now = clock.Now;
        var claims = new AccessClaims
        {
            Subject = request.Subject,
            Roles = [.. request.Roles],
            TokenId = ids.NewId().ToString(),
            SessionId = request.SessionId ?? UuidText.Nil,
            Version = request.Version,
            ExpiresAt = now + signing.Ttl,
        };
        var header = Segment(w =>
        {
            w.WriteString("alg", "EdDSA");
            w.WriteString("kid", signing.KeyId);
            w.WriteString("typ", "JWT");
        });
        var payload = Segment(w => WritePayload(w, claims, now));
        var signingInput = header + "." + payload;
        var signature = Ed25519Keys.Sign(signing.Key, Encoding.ASCII.GetBytes(signingInput));
        return (signingInput + "." + WebEncoders.Base64UrlEncode(signature), claims);
    }

    private static void WritePayload(Utf8JsonWriter w, AccessClaims claims, DateTimeOffset now)
    {
        w.WriteStartArray("roles");
        foreach (var role in claims.Roles)
        {
            w.WriteStringValue(role);
        }
        w.WriteEndArray();
        w.WriteNumber("ver", claims.Version);
        w.WriteString("sid", claims.SessionId);
        w.WriteString("iss", "pao");
        w.WriteString("sub", claims.Subject);
        w.WriteNumber("exp", claims.ExpiresAt.ToUnixTimeSeconds());
        w.WriteNumber("iat", now.ToUnixTimeSeconds());
        w.WriteString("jti", claims.TokenId);
    }

    private static string Segment(Action<Utf8JsonWriter> write)
    {
        using var buffer = new MemoryStream();
        using (var writer = new Utf8JsonWriter(buffer))
        {
            writer.WriteStartObject();
            write(writer);
            writer.WriteEndObject();
        }
        return WebEncoders.Base64UrlEncode(buffer.ToArray());
    }
}
