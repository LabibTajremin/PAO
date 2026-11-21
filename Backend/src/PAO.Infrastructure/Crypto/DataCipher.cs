using System.Security.Cryptography;
using System.Text;

namespace PAO.Infrastructure.Crypto;

/// <summary>Thrown for data that this key did not produce.</summary>
public sealed class CiphertextException() : Exception("ciphertext invalid");

/// <summary>
/// Encrypts sensitive fields (NID numbers, TOTP secrets) with AES-GCM as `nonce ‖
/// ciphertext ‖ tag`, the layout Go's cipher.AEAD.Seal produces, and
/// derives keyed lookup hashes so equal values can be found without decrypting.
/// Rotation (ADR-0036): new data uses the current key; data under a previous key still
/// decrypts until `migrate reencrypt` rewrites it. Lookup hashes always use the original key
/// (the last previous key, or the current one when there are none) because blocked NIDs are
/// stored only as hashes and could never be re-hashed.
/// </summary>
public sealed class DataCipher
{
    private const int NonceBytes = 12;
    private const int TagBytes = 16;
    private readonly byte[] key;
    private readonly IReadOnlyList<byte[]> previousKeys;
    private readonly byte[] macKey;

    /// <summary>Uses a 16, 24 or 32-byte AES key (DATA_ENCRYPTION_KEY is 32) and no previous keys.</summary>
    public DataCipher(byte[] key)
        : this(key, [])
    {
    }

    /// <summary>
    /// Uses `key` for new data and also decrypts with `previousKeys`
    /// (DATA_ENCRYPTION_PREVIOUS_KEYS, newest first, the original key last).
    /// </summary>
    public DataCipher(byte[] key, IReadOnlyList<byte[]> previousKeys)
    {
        foreach (var candidate in previousKeys.Prepend(key))
        {
            if (candidate.Length is not (16 or 24 or 32))
            {
                throw new ArgumentException($"data key: invalid key size {candidate.Length}", nameof(key));
            }
        }
        this.key = key;
        this.previousKeys = previousKeys;
        macKey = HMACSHA256.HashData(previousKeys.Count > 0 ? previousKeys[^1] : key, "pao-lookup-hash"u8);
    }

    /// <summary>Returns nonce ‖ ciphertext ‖ tag under the current key.</summary>
    public byte[] Encrypt(byte[] plaintext)
    {
        var output = new byte[NonceBytes + plaintext.Length + TagBytes];
        var nonce = output.AsSpan(0, NonceBytes);
        RandomNumberGenerator.Fill(nonce);
        using var aes = new AesGcm(key, TagBytes);
        aes.Encrypt(nonce, plaintext, output.AsSpan(NonceBytes, plaintext.Length), output.AsSpan(NonceBytes + plaintext.Length));
        return output;
    }

    /// <summary>Reverses <see cref="Encrypt"/> under any known key; throws <see cref="CiphertextException"/> for anything else.</summary>
    public byte[] Decrypt(byte[] data)
    {
        foreach (var candidate in previousKeys.Prepend(key))
        {
            if (TryDecrypt(candidate, data) is { } plaintext)
            {
                return plaintext;
            }
        }
        throw new CiphertextException();
    }

    /// <summary>
    /// Returns `data` encrypted under the current key, or null when it already is; throws
    /// <see cref="CiphertextException"/> when no known key opens it (`migrate reencrypt`).
    /// </summary>
    public byte[]? Reencrypt(byte[] data) =>
        TryDecrypt(key, data) is null ? Encrypt(Decrypt(data)) : null;

    /// <summary>Returns a keyed hash (hex) of `value` for equality lookups.</summary>
    public string LookupHash(string value) =>
        Convert.ToHexStringLower(HMACSHA256.HashData(macKey, Encoding.UTF8.GetBytes(value)));

    private static byte[]? TryDecrypt(byte[] candidate, byte[] data)
    {
        if (data.Length < NonceBytes + TagBytes)
        {
            return null;
        }
        var bodyLength = data.Length - NonceBytes - TagBytes;
        var plaintext = new byte[bodyLength];
        using var aes = new AesGcm(candidate, TagBytes);
        try
        {
            aes.Decrypt(data.AsSpan(0, NonceBytes), data.AsSpan(NonceBytes, bodyLength), data.AsSpan(NonceBytes + bodyLength), plaintext);
            return plaintext;
        }
        catch (AuthenticationTagMismatchException)
        {
            return null;
        }
    }
}

/// <summary>Random tokens and digits from the CSPRNG.</summary>
public static class RandomSecrets
{
    /// <summary>A URL-safe token with `bytes` bytes of entropy (refresh tokens use 32).</summary>
    public static string Token(int bytes) => Microsoft.AspNetCore.WebUtilities.WebEncoders.Base64UrlEncode(RandomNumberGenerator.GetBytes(bytes));

    /// <summary>`n` decimal digits (OTPs, start codes).</summary>
    public static string Digits(int n) => string.Create(n, 0, (span, _) =>
    {
        for (var i = 0; i < span.Length; i++)
        {
            span[i] = (char)('0' + RandomNumberGenerator.GetInt32(10));
        }
    });

    /// <summary>Hashes a high-entropy token for storage; low-entropy secrets use argon2id instead.</summary>
    public static string Sha256Hex(string value) => Convert.ToHexStringLower(SHA256.HashData(Encoding.UTF8.GetBytes(value)));
}
