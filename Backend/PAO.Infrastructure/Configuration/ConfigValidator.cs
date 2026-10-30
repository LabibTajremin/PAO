using PAO.Infrastructure.Hosting;

namespace PAO.Infrastructure.Configuration;

/// <summary>Thrown at start when the configuration is incomplete; lists every problem at once.</summary>
public sealed class ConfigException(IReadOnlyList<string> problems)
    : Exception("invalid configuration: " + string.Join("; ", problems))
{
    /// <summary>Each problem, named after the environment variable that fixes it.</summary>
    public IReadOnlyList<string> Problems { get; } = problems;
}

/// <summary>
/// Checks the bound settings with stable rules and messages, so a
/// deployment's existing configuration starts or fails with the same complaints.
/// </summary>
public static class ConfigValidator
{
    /// <summary>Size of an Ed25519 seed, a raw Ed25519 public key and the AES-256 data key.</summary>
    public const int KeyBytes = 32;

    /// <summary>Throws <see cref="ConfigException"/> unless `settings` are complete and valid.</summary>
    public static PaoSettings Validate(PaoSettings settings)
    {
        var problems = new List<string>();
        CheckApp(settings, problems);
        CheckServices(settings, problems);
        CheckKeys(settings, problems);
        CheckAdapters(settings, problems);
        if (problems.Count > 0)
        {
            throw new ConfigException(problems);
        }
        return settings;
    }

    /// <summary>Parses `kid:base64,kid2:base64`; reports malformed entries to `problems`.</summary>
    public static Dictionary<string, byte[]> PreviousKeys(string list, List<string> problems)
    {
        var keys = new Dictionary<string, byte[]>(StringComparer.Ordinal);
        foreach (var pair in list.Split(',', StringSplitOptions.RemoveEmptyEntries))
        {
            var colon = pair.IndexOf(':', StringComparison.Ordinal);
            var kid = colon < 0 ? pair : pair[..colon];
            var raw = colon < 0 ? null : StrictBase64.Decode(pair[(colon + 1)..]);
            if (kid.Length == 0 || raw?.Length != KeyBytes)
            {
                problems.Add($"JWT_PREVIOUS_PUBLIC_KEYS entry \"{kid}\" must be kid:base64-public-key");
                continue;
            }
            keys[kid] = raw;
        }
        return keys;
    }

    private static void CheckApp(PaoSettings s, List<string> problems)
    {
        if (s.App.Environment is not (AppEnvironments.Dev or AppEnvironments.Test or AppEnvironments.Staging or AppEnvironments.Prod))
        {
            problems.Add("APP_ENV must be one of dev, test, staging, prod");
        }
        if (s.Logging.Level.ToLowerInvariant() is not ("debug" or "info" or "warn" or "error"))
        {
            problems.Add("LOG_LEVEL must be debug, info, warn or error");
        }
        if (!ListenAddress.IsValid(s.Http.Address))
        {
            problems.Add("HTTP_ADDR must be a host:port listen address");
        }
        if (!ListenAddress.IsValid(s.Http.MetricsAddress))
        {
            problems.Add("METRICS_ADDR must be a host:port listen address");
        }
        var origins = CorsOrigins.Parse(s.App.AdminCorsOrigin);
        if (origins.Count == 0 || !origins.All(CorsOrigins.IsValid))
        {
            problems.Add("ADMIN_CORS_ORIGIN must be one or more comma-separated http(s) origins without a path");
        }
    }

    private static void CheckServices(PaoSettings s, List<string> problems)
    {
        Require(problems, "DATABASE_URL", s.Database.Url);
        Require(problems, "REDIS_URL", s.Redis.Url);
        Require(problems, "S3_ENDPOINT", s.Storage.Endpoint);
        Require(problems, "S3_ACCESS_KEY", s.Storage.AccessKey);
        Require(problems, "S3_SECRET_KEY", s.Storage.SecretKey);
        Require(problems, "S3_BUCKET_PRIVATE", s.Storage.BucketPrivate);
        Require(problems, "S3_BUCKET_PUBLIC", s.Storage.BucketPublic);
    }

    private static void CheckKeys(PaoSettings s, List<string> problems)
    {
        CheckKey(problems, "JWT_SIGNING_KEY", s.Jwt.SigningKey);
        PreviousKeys(s.Jwt.PreviousPublicKeys, problems);
        CheckKey(problems, "DATA_ENCRYPTION_KEY", s.App.DataEncryptionKey);
        DataKeys(s.App.DataEncryptionPreviousKeys, problems);
    }

    /// <summary>Parses DATA_ENCRYPTION_PREVIOUS_KEYS (`base64,base64`); reports malformed entries to `problems`.</summary>
    public static List<byte[]> DataKeys(string list, List<string> problems)
    {
        var keys = new List<byte[]>();
        foreach (var entry in list.Split(',', StringSplitOptions.RemoveEmptyEntries | StringSplitOptions.TrimEntries))
        {
            if (StrictBase64.Decode(entry) is { Length: KeyBytes } key)
            {
                keys.Add(key);
                continue;
            }
            problems.Add($"DATA_ENCRYPTION_PREVIOUS_KEYS entries must be {KeyBytes} bytes, base64-encoded");
        }
        return keys;
    }

    private static void CheckAdapters(PaoSettings s, List<string> problems)
    {
        var sms = s.Sms.Adapter;
        var push = s.Push.Adapter;
        if (sms is not ("console" or "sslwireless"))
        {
            problems.Add("SMS_ADAPTER must be one of console, sslwireless");
        }
        if (push is not ("log" or "fcm"))
        {
            problems.Add("PUSH_ADAPTER must be one of log, fcm");
        }
        if (sms == "sslwireless")
        {
            Require(problems, "SSLWIRELESS_API_TOKEN", s.Sms.SslWirelessApiToken);
            Require(problems, "SSLWIRELESS_SID", s.Sms.SslWirelessSid);
        }
        if (push == "fcm")
        {
            if (s.Push.FcmCredentialsFile.Length == 0 && s.Push.FcmCredentialsJson.Length == 0)
            {
                problems.Add("FCM_CREDENTIALS_FILE or FCM_CREDENTIALS_JSON is required");
            }
        }
        if (s.App.Environment == AppEnvironments.Prod && (sms == "console" || push == "log"))
        {
            problems.Add("production needs real SMS_ADAPTER and PUSH_ADAPTER");
        }
    }

    private static void Require(List<string> problems, string name, string value)
    {
        if (string.IsNullOrEmpty(value))
        {
            problems.Add($"{name} is required");
        }
    }

    private static void CheckKey(List<string> problems, string name, string value)
    {
        if (string.IsNullOrEmpty(value))
        {
            problems.Add($"{name} is required");
        }
        else if (StrictBase64.Decode(value)?.Length != KeyBytes)
        {
            problems.Add($"{name} must be {KeyBytes} bytes, base64-encoded");
        }
    }
}
