using Org.BouncyCastle.Crypto.Parameters;
using PAO.Infrastructure.Configuration;

namespace PAO.Infrastructure.Crypto;

/// <summary>The signing key and every public key tokens may be verified with.</summary>
public sealed record JwtKeyRing(SigningKey Signing, IReadOnlyDictionary<string, Ed25519PublicKeyParameters> VerificationKeys)
{
    /// <summary>Builds the ring from validated options (JWT_SIGNING_KEY, JWT_KEY_ID, JWT_PREVIOUS_PUBLIC_KEYS).</summary>
    public static JwtKeyRing From(JwtOptions options)
    {
        var problems = new List<string>();
        var previous = ConfigValidator.PreviousKeys(options.PreviousPublicKeys, problems);
        var seed = StrictBase64.Decode(options.SigningKey);
        if (problems.Count > 0 || seed is null)
        {
            throw new ConfigException([.. problems, "JWT_SIGNING_KEY must be 32 bytes, base64-encoded"]);
        }
        var key = Ed25519Keys.FromSeed(seed);
        var verification = previous.ToDictionary(p => p.Key, p => Ed25519Keys.FromRaw(p.Value), StringComparer.Ordinal);
        verification[options.KeyId] = key.GeneratePublicKey();
        return new JwtKeyRing(new SigningKey(options.KeyId, key, TimeSpan.FromSeconds(options.AccessTokenTtlSeconds)), verification);
    }
}
