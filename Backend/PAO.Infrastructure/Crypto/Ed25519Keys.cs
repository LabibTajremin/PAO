using Org.BouncyCastle.Crypto.Parameters;
using Org.BouncyCastle.Crypto.Signers;

namespace PAO.Infrastructure.Crypto;

/// <summary>
/// Ed25519 keys kept in the environment as raw base64 bytes (a 32-byte seed for the
/// private key, 32 raw bytes for public keys), the format Go's crypto/ed25519 and the
/// NestJS backend read, so existing keys load unchanged.
/// </summary>
public static class Ed25519Keys
{
    /// <summary>Size in bytes of a seed and of a raw public key.</summary>
    public const int KeyBytes = 32;

    /// <summary>The private key for a 32-byte seed.</summary>
    public static Ed25519PrivateKeyParameters FromSeed(byte[] seed) => new(Checked(seed), 0);

    /// <summary>The public key for its 32 raw bytes.</summary>
    public static Ed25519PublicKeyParameters FromRaw(byte[] raw) => new(Checked(raw), 0);

    /// <summary>Signs `data` with `key`.</summary>
    public static byte[] Sign(Ed25519PrivateKeyParameters key, byte[] data)
    {
        var signer = new Ed25519Signer();
        signer.Init(true, key);
        signer.BlockUpdate(data, 0, data.Length);
        return signer.GenerateSignature();
    }

    /// <summary>Reports whether `signature` is `key`'s signature of `data`.</summary>
    public static bool Verify(Ed25519PublicKeyParameters key, byte[] data, byte[] signature)
    {
        var verifier = new Ed25519Signer();
        verifier.Init(false, key);
        verifier.BlockUpdate(data, 0, data.Length);
        return verifier.VerifySignature(signature);
    }

    private static byte[] Checked(byte[] bytes) =>
        bytes.Length == KeyBytes ? bytes : throw new ArgumentException($"Ed25519 keys are {KeyBytes} bytes", nameof(bytes));
}
