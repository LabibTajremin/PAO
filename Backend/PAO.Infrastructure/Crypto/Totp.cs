using System.Text;
using OtpNet;

namespace PAO.Infrastructure.Crypto;

/// <summary>A new admin TOTP secret and the otpauth:// URL their authenticator app scans (A-01).</summary>
public sealed record TotpEnrolment(string Secret, string Url);

/// <summary>
/// RFC 6238 codes (SHA-1, 6 digits, 30 s) with base32 secrets, as otplib produced them for
/// earlier releases, so enrolled authenticator apps keep working.
/// </summary>
public static class Totp
{
    private const int PeriodSeconds = 30;

    /// <summary>Creates a 20-byte secret (base32) for `account`.</summary>
    public static TotpEnrolment NewSecret(string account)
    {
        if (account.Length == 0)
        {
            throw new ArgumentException("generate totp secret: account name is required", nameof(account));
        }
        var secret = Base32Encoding.ToString(KeyGeneration.GenerateRandomKey(20));
        var label = EncodeComponent($"PAO:{account}").Replace("%3A", ":", StringComparison.Ordinal).Replace("%40", "@", StringComparison.Ordinal);
        var query = $"algorithm=SHA1&digits=6&issuer=PAO&period={PeriodSeconds}&secret={secret}";
        return new TotpEnrolment(secret, $"otpauth://totp/{label}?{query}");
    }

    /// <summary>
    /// Checks a 6-digit code at `now`, allowing one 30-second step of drift either way. A
    /// malformed secret or code is simply not valid.
    /// </summary>
    public static bool Validate(string code, string secret, DateTimeOffset now)
    {
        if (code.Length != 6 || !code.All(char.IsAsciiDigit) || Key(secret) is not { } key)
        {
            return false;
        }
        return new OtpNet.Totp(key, PeriodSeconds).VerifyTotp(now.UtcDateTime, code, out _, new VerificationWindow(1, 1));
    }

    /// <summary>The code for `secret` at `now`; used by tests and the e2e suite.</summary>
    public static string Code(string secret, DateTimeOffset now) =>
        new OtpNet.Totp(Key(secret) ?? throw new ArgumentException("secret is not base32", nameof(secret)), PeriodSeconds)
            .ComputeTotp(now.UtcDateTime);

    private static byte[]? Key(string secret)
    {
        try
        {
            var key = Base32Encoding.ToBytes(secret);
            return key.Length == 0 ? null : key;
        }
        catch (ArgumentException)
        {
            return null;
        }
    }

    // encodeURIComponent: RFC 3986 escaping, but leaves !'()* alone.
    private static string EncodeComponent(string value)
    {
        var escaped = new StringBuilder(Uri.EscapeDataString(value));
        foreach (var c in "!'()*")
        {
            escaped.Replace("%" + ((int)c).ToString("X2", System.Globalization.CultureInfo.InvariantCulture), c.ToString());
        }
        return escaped.ToString();
    }
}
