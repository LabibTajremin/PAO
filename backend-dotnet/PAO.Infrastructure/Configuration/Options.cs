namespace PAO.Infrastructure.Configuration;

/// <summary>Deployment environment and app-wide settings (`Config/app.json`).</summary>
public sealed class AppOptions
{
    public const string Section = "App";

    /// <summary>dev | test | staging | prod; "test" mounts the e2e test hooks.</summary>
    public string Environment { get; set; } = AppEnvironments.Dev;
    public string AdminCorsOrigin { get; set; } = "http://localhost:5000";

    /// <summary>AES-256 key (base64) for encrypted fields; a secret, from DATA_ENCRYPTION_KEY.</summary>
    public string DataEncryptionKey { get; set; } = string.Empty;
    public string SeedAdminPassword { get; set; } = string.Empty;
}

/// <summary>The values of APP_ENV.</summary>
public static class AppEnvironments
{
    public const string Dev = "dev";
    public const string Test = "test";
    public const string Staging = "staging";
    public const string Prod = "prod";
}

/// <summary>PostgreSQL (`Config/database.json`).</summary>
public sealed class DatabaseOptions
{
    public const string Section = "Database";
    public string Url { get; set; } = string.Empty;
}

/// <summary>Redis (`Config/redis.json`).</summary>
public sealed class RedisOptions
{
    public const string Section = "Redis";
    public string Url { get; set; } = string.Empty;
}

/// <summary>Access-token keys (`Config/jwt.json`); the keys themselves come from the environment.</summary>
public sealed class JwtOptions
{
    public const string Section = "Jwt";
    public string KeyId { get; set; } = "k1";
    public string SigningKey { get; set; } = string.Empty;

    /// <summary>Public keys still accepted during rotation: `kid:base64pub,kid2:base64pub`.</summary>
    public string PreviousPublicKeys { get; set; } = string.Empty;
    public int AccessTokenTtlSeconds { get; set; } = 900;
}

/// <summary>Log level and the folder of the date-named log directories (`Config/logging.json`).</summary>
public sealed class LoggingOptions
{
    public const string Section = "Logging";
    public string Level { get; set; } = "info";
    public string Directory { get; set; } = "Logs";
    public bool WriteFiles { get; set; } = true;
}

/// <summary>Outgoing mail (`Config/smtp.json`); no feature sends mail yet.</summary>
public sealed class SmtpOptions
{
    public const string Section = "Smtp";
    public string Host { get; set; } = string.Empty;
    public int Port { get; set; } = 587;
    public bool UseTls { get; set; } = true;
    public string From { get; set; } = string.Empty;
    public string Username { get; set; } = string.Empty;
    public string Password { get; set; } = string.Empty;
}

/// <summary>S3-compatible storage (`Config/storage.json`).</summary>
public sealed class StorageOptions
{
    public const string Section = "Storage";
    public string Endpoint { get; set; } = string.Empty;

    /// <summary>What devices reach; inside Docker it differs from <see cref="Endpoint"/>.</summary>
    public string PublicEndpoint { get; set; } = string.Empty;
    public string Region { get; set; } = "us-east-1";
    public string AccessKey { get; set; } = string.Empty;
    public string SecretKey { get; set; } = string.Empty;
    public string BucketPrivate { get; set; } = string.Empty;
    public string BucketPublic { get; set; } = string.Empty;
}

/// <summary>Text messages (`Config/sms.json`).</summary>
public sealed class SmsOptions
{
    public const string Section = "Sms";

    /// <summary>console | sslwireless.</summary>
    public string Adapter { get; set; } = "console";
    public string SslWirelessEndpoint { get; set; } = "https://smsplus.sslwireless.com/api/v3/send-sms";
    public string SslWirelessApiToken { get; set; } = string.Empty;
    public string SslWirelessSid { get; set; } = string.Empty;
    public int TimeoutSeconds { get; set; } = 10;
}

/// <summary>Push notifications (`Config/push.json`).</summary>
public sealed class PushOptions
{
    public const string Section = "Push";

    /// <summary>log | fcm.</summary>
    public string Adapter { get; set; } = "log";
    public string FcmCredentialsFile { get; set; } = string.Empty;
}

/// <summary>The worker's relay and jobs (`Config/jobs.json`).</summary>
public sealed class JobsOptions
{
    public const string Section = "Jobs";
    public int OutboxRelayIntervalMs { get; set; } = 250;
    public int OutboxRetentionDays { get; set; } = 7;
}

/// <summary>Listen addresses, body limit and API rate limits (`Config/http.json`).</summary>
public sealed class HttpOptions
{
    public const string Section = "Http";
    public string Address { get; set; } = ":8080";

    /// <summary>The internal address of /metrics (never exposed publicly).</summary>
    public string MetricsAddress { get; set; } = ":9090";
    public int MaxBodyBytes { get; set; } = 1 << 20;
    public int RateLimitPerUser { get; set; } = 120;
    public int RateLimitPerIp { get; set; } = 60;
    public int RateLimitWindowSeconds { get; set; } = 60;
}
