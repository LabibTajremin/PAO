using System.Globalization;
using System.Security.Cryptography;
using System.Text;
using System.Text.RegularExpressions;
using Konscious.Security.Cryptography;

namespace PAO.Infrastructure.Crypto;

/// <summary>argon2id cost settings; memory in KiB.</summary>
public sealed record Argon2Params(int Memory, int Time, int Threads)
{
    /// <summary>Passwords: the OWASP-recommended cost the Go and NestJS backends used.</summary>
    public static readonly Argon2Params Password = new(64 * 1024, 3, 2);

    /// <summary>One-time codes live five minutes and allow five attempts, so a cheaper cost is enough.</summary>
    public static readonly Argon2Params Code = new(8 * 1024, 1, 1);
}

/// <summary>Thrown for a stored hash in an unknown format.</summary>
public sealed class HashMalformedException() : Exception("password hash malformed");

/// <summary>
/// argon2id (version 0x13) hashes in PHC format, `$argon2id$v=19$m=…,t=…,p=…$salt$key`,
/// byte-compatible with the hashes the Go and NestJS backends stored.
/// </summary>
public static partial class SecretHasher
{
    private const int SaltBytes = 16;
    private const int KeyBytes = 32;

    /// <summary>Returns the PHC-encoded argon2id hash of `secret`.</summary>
    public static async Task<string> Hash(string secret, Argon2Params p)
    {
        var salt = RandomNumberGenerator.GetBytes(SaltBytes);
        var key = await Derive(secret, salt, p, KeyBytes);
        return string.Create(CultureInfo.InvariantCulture, $"$argon2id$v=19$m={p.Memory},t={p.Time},p={p.Threads}${Raw(salt)}${Raw(key)}");
    }

    /// <summary>Reports whether `secret` matches `encoded`, comparing in constant time.</summary>
    public static async Task<bool> Verify(string secret, string encoded)
    {
        var parts = encoded.Split('$');
        var match = parts.Length == 6 ? ParamsText().Match(parts[3]) : Match.Empty;
        var salt = parts.Length == 6 ? DecodeRaw(parts[4]) : null;
        var want = parts.Length == 6 ? DecodeRaw(parts[5]) : null;
        if (parts.Length != 6 || parts[1] != "argon2id" || !match.Success || salt is null || want is null)
        {
            throw new HashMalformedException();
        }
        var p = new Argon2Params(Int(match, 1), Int(match, 2), Int(match, 3));
        var got = await Derive(secret, salt, p, want.Length);
        return CryptographicOperations.FixedTimeEquals(got, want);
    }

    private static async Task<byte[]> Derive(string secret, byte[] salt, Argon2Params p, int length)
    {
        using var argon = new Argon2id(Encoding.UTF8.GetBytes(secret))
        {
            Salt = salt,
            MemorySize = p.Memory,
            Iterations = p.Time,
            DegreeOfParallelism = p.Threads,
        };
        return await argon.GetBytesAsync(length);
    }

    private static int Int(Match match, int group) => int.Parse(match.Groups[group].Value, CultureInfo.InvariantCulture);

    private static string Raw(byte[] bytes) => Convert.ToBase64String(bytes).TrimEnd('=');

    private static byte[]? DecodeRaw(string text)
    {
        if (!RawBase64().IsMatch(text) || text.Length % 4 == 1)
        {
            return null;
        }
        return Convert.FromBase64String(text.PadRight(text.Length + ((4 - (text.Length % 4)) % 4), '='));
    }

    [GeneratedRegex(@"^m=(\d+),t=(\d+),p=(\d+)$")]
    private static partial Regex ParamsText();

    [GeneratedRegex("^[A-Za-z0-9+/]+$")]
    private static partial Regex RawBase64();
}
