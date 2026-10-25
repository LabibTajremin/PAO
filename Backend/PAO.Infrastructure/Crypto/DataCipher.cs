using System.Security.Cryptography;
using System.Text;

namespace PAO.Infrastructure.Crypto;

/// <summary>Thrown for data that this key did not produce.</summary>
public sealed class CiphertextException() : Exception("ciphertext invalid");

/// <summary>
/// Encrypts sensitive fields (NID numbers, TOTP secrets) with AES-GCM as `nonce ‖
/// ciphertext ‖ tag`, the layout Go's cipher.AEAD.Seal produces, and
/// derives keyed lookup hashes so equal values can be found without decrypting.
/// </summary>
public sealed class DataCipher
{
    private const int NonceBytes = 12;
    private const int TagBytes = 16;
    private readonly byte[] key;
    private readonly byte[] macKey;

    /// <summary>Uses a 16, 24 or 32-byte AES key (DATA_ENCRYPTION_KEY is 32).</summary>
    public DataCipher(byte[] key)
    {
        if (key.Length is not (16 or 24 or 32))
        {
            throw new ArgumentException($"data key: invalid key size {key.Length}", nameof(key));
        }
        this.key = key;
        macKey = HMACSHA256.HashData(key, "pao-lookup-hash"u8);
    }

    /// <summary>Returns nonce ‖ ciphertext ‖ tag.</summary>
    public byte[] Encrypt(byte[] plaintext)
    {
        var output = new byte[NonceBytes + plaintext.Length + TagBytes];
        var nonce = output.AsSpan(0, NonceBytes);
        RandomNumberGenerator.Fill(nonce);
        using var aes = new AesGcm(key, TagBytes);
        aes.Encrypt(nonce, plaintext, output.AsSpan(NonceBytes, plaintext.Length), output.AsSpan(NonceBytes + plaintext.Length));
        return output;
    }

    /// <summary>Reverses <see cref="Encrypt"/>; throws <see cref="CiphertextException"/> for anything else.</summary>
    public byte[] Decrypt(byte[] data)
    {
        if (data.Length < NonceBytes + TagBytes)
        {
            throw new CiphertextException();
        }
        var bodyLength = data.Length - NonceBytes - TagBytes;
        var plaintext = new byte[bodyLength];
        using var aes = new AesGcm(key, TagBytes);
        try
        {
            aes.Decrypt(data.AsSpan(0, NonceBytes), data.AsSpan(NonceBytes, bodyLength), data.AsSpan(NonceBytes + bodyLength), plaintext);
        }
        catch (AuthenticationTagMismatchException)
        {
            throw new CiphertextException();
        }
        return plaintext;
    }

    /// <summary>Returns a keyed hash (hex) of `value` for equality lookups.</summary>
    public string LookupHash(string value) =>
        Convert.ToHexStringLower(HMACSHA256.HashData(macKey, Encoding.UTF8.GetBytes(value)));
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
